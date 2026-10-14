package by.quake.zircon;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.SystemClock;
import android.util.SparseArray;
import android.view.DisplayCutout;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowInsets;

/**
 * Quad Touch style FPS controls drawn above the SDL surface, driven by a ControlLayout.
 * Left zone: floating analog stick. Elsewhere: look pad. Buttons send engine key names
 * (so they honour binds) or console commands. Outside gameplay the first finger drives
 * the menu cursor. In edit mode touches move, resize and select controls instead.
 */
public class TouchOverlay extends View {

    static native void nativeSetMove(float x, float y);
    static native void nativeAddLook(float dx, float dy);
    static native void nativeKey(String keyName, boolean down);
    static native void nativeCommand(String command);
    static native int nativeGetState();
    static native void nativeMenuPointer(float x, float y, int phase);
    static native void nativeRequestKeyboard(boolean show);

    interface Listener {
        /** a tap-mode button was held long enough to ask for the layout editor */
        void onEditRequested();

        /** editor selection changed; control is null when nothing is selected */
        void onSelectionChanged(ControlLayout.Control control);
    }

    static final String[] ICON_NAMES = {
        "fire", "aim", "jump", "crouch", "reload", "use", "run", "grenade", "heal", "light",
        "next", "prev", "score", "menu", "console", "keyboard", "text"
    };

    private static final int POINTER_MOVE = 0;
    private static final int POINTER_DOWN = 1;
    private static final int POINTER_UP = 2;

    private static final int STATE_IN_GAME = 1;
    private static final int STATE_CONSOLE = 2;
    /** game code is drawing its own mouse cursor (ObjectN lobby and page UI): touches drive that cursor */
    private static final int STATE_CURSOR_UI = 8;

    private static final int ROLE_STICK = 1;
    private static final int ROLE_LOOK = 2;
    private static final int ROLE_CONTROL = 3;

    private static final long LONG_PRESS_MS = 900;

    private static final class Pointer {
        int role;
        ControlLayout.Control control;
        float lastX, lastY;
        long downTime;
    }

    private final float density;
    private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint iconStroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint iconFill = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint text = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint dashed = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final RectF oval = new RectF();
    private final SparseArray<Pointer> pointers = new SparseArray<>();
    private final Rect safe = new Rect();
    private final float stickRadius;

    private ControlLayout layout;
    private Listener listener;
    private boolean inGame;
    private boolean consoleOpen;
    private boolean cursorUi;
    private boolean editing;
    private boolean gamepadHidden;
    private float stickBaseX, stickBaseY, stickKnobX, stickKnobY;
    private boolean stickActive;
    private float areaLeft, areaTop, areaWidth = 1, areaHeight = 1;

    // editor gesture state
    private ControlLayout.Control selected;
    private int dragPointerId = -1;
    private float dragOffX, dragOffY;
    private boolean pinching;
    private float pinchStartDist, pinchStartSize;

    public TouchOverlay(Context context, ControlLayout layout) {
        super(context);
        this.layout = layout;
        density = getResources().getDisplayMetrics().density;
        stickRadius = 64 * density;

        fill.setStyle(Paint.Style.FILL);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(1.5f * density);
        iconStroke.setStyle(Paint.Style.STROKE);
        iconStroke.setStrokeCap(Paint.Cap.ROUND);
        iconStroke.setStrokeJoin(Paint.Join.ROUND);
        iconFill.setStyle(Paint.Style.FILL);
        text.setTextAlign(Paint.Align.CENTER);
        text.setFakeBoldText(true);
        dashed.setStyle(Paint.Style.STROKE);
        dashed.setStrokeWidth(1.5f * density);
        dashed.setPathEffect(new DashPathEffect(new float[] { 8 * density, 6 * density }, 0));

        setFocusable(false);
        post(statePoll);
    }

    void setListener(Listener listener) {
        this.listener = listener;
    }

    ControlLayout getControlLayout() {
        return layout;
    }

    void setControlLayout(ControlLayout newLayout) {
        releaseAll();
        layout = newLayout;
        select(null);
        layoutControls();
        invalidate();
    }

    /** call after changing control fields from outside (editor dialogs) */
    void refresh() {
        layoutControls();
        invalidate();
    }

    boolean isEditing() {
        return editing;
    }

    void startEditing() {
        releaseAll();
        editing = true;
        gamepadHidden = false;
        refresh();
    }

    void stopEditing() {
        editing = false;
        select(null);
        invalidate();
    }

    ControlLayout.Control getSelected() {
        return selected;
    }

    void select(ControlLayout.Control control) {
        selected = control;
        if (listener != null) {
            listener.onSelectionChanged(control);
        }
        invalidate();
    }

    /** hide the controls while a gamepad is in use; the next touch brings them back */
    void setGamepadActive(boolean active) {
        if (active == gamepadHidden || editing) {
            return;
        }
        gamepadHidden = active;
        if (active) {
            releaseAll();
        }
        invalidate();
    }

    private final Runnable statePoll = new Runnable() {
        @Override
        public void run() {
            int state;
            try {
                state = nativeGetState();
            } catch (UnsatisfiedLinkError e) {
                state = 0;
            }
            boolean nowInGame = (state & STATE_IN_GAME) != 0;
            boolean nowConsole = (state & STATE_CONSOLE) != 0;
            boolean nowCursor = (state & STATE_CURSOR_UI) != 0;
            if (nowInGame != inGame || nowConsole != consoleOpen || nowCursor != cursorUi) {
                inGame = nowInGame;
                consoleOpen = nowConsole;
                cursorUi = nowCursor;
                if (!inGame || cursorUi) {
                    releaseAll();
                }
                // SDL adds its text-input view to the same layout when the keyboard opens; stay above it
                bringToFront();
                invalidate();
            }
            postDelayed(this, 100);
        }
    };

    @Override
    public WindowInsets onApplyWindowInsets(WindowInsets insets) {
        int l = 0, t = 0, r = 0, b = 0;
        DisplayCutout cutout = insets.getDisplayCutout();
        if (cutout != null) {
            l = cutout.getSafeInsetLeft();
            t = cutout.getSafeInsetTop();
            r = cutout.getSafeInsetRight();
            b = cutout.getSafeInsetBottom();
        }
        safe.set(l, t, r, b);
        layoutControls();
        return insets;
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        layoutControls();
    }

    private void layoutControls() {
        int w = getWidth(), h = getHeight();
        if (w == 0 || h == 0) {
            return;
        }
        float margin = 16 * density;
        areaLeft = safe.left + margin;
        areaTop = safe.top + margin;
        areaWidth = Math.max(1, w - safe.left - safe.right - 2 * margin);
        areaHeight = Math.max(1, h - safe.top - safe.bottom - 2 * margin);
        for (ControlLayout.Control c : layout.controls) {
            c.r = c.size * density * layout.scale;
            c.cx = areaLeft + c.x * areaWidth;
            c.cy = areaTop + c.y * areaHeight;
        }
    }

    private boolean shownNow(ControlLayout.Control c) {
        if (editing) {
            return true;
        }
        if (!c.visible || gamepadHidden) {
            return false;
        }
        if (cursorUi) {
            // the game's own cursor owns the screen; only buttons meant for both modes stay (menu, console)
            return ControlLayout.SHOW_BOTH.equals(c.show);
        }
        if (inGame) {
            return !ControlLayout.SHOW_CONSOLE.equals(c.show);
        }
        return consoleOpen && !ControlLayout.SHOW_GAME.equals(c.show);
    }

    private ControlLayout.Control controlAt(float x, float y) {
        ControlLayout.Control best = null;
        float bestDist = Float.MAX_VALUE;
        for (ControlLayout.Control c : layout.controls) {
            if (!shownNow(c)) {
                continue;
            }
            float dx = x - c.cx, dy = y - c.cy;
            float d = dx * dx + dy * dy;
            float slop = c.r * 1.25f;
            if (d <= slop * slop && d < bestDist) {
                bestDist = d;
                best = c;
            }
        }
        return best;
    }

    private void releaseAll() {
        if (layout != null) {
            for (ControlLayout.Control c : layout.controls) {
                if (c.down) {
                    c.down = false;
                    if (!ControlLayout.MODE_TAP.equals(c.mode)) {
                        press(c, false);
                    }
                }
            }
        }
        pointers.clear();
        if (stickActive) {
            stickActive = false;
        }
        try {
            nativeSetMove(0, 0);
        } catch (UnsatisfiedLinkError ignored) {
            // engine library not loaded yet
        }
    }

    /** sends the control's action; "+command" actions send the matching "-command" on release */
    private void press(ControlLayout.Control c, boolean down) {
        if (ControlLayout.TYPE_KEYBOARD.equals(c.type)) {
            if (down) {
                nativeRequestKeyboard(true);
            }
            return;
        }
        String action = c.action == null ? "" : c.action.trim();
        if (action.isEmpty()) {
            return;
        }
        if (ControlLayout.TYPE_COMMAND.equals(c.type)) {
            boolean paired = action.startsWith("+") && action.indexOf(' ') < 0 && action.indexOf(';') < 0;
            if (paired) {
                nativeCommand(down ? action : "-" + action.substring(1));
            } else if (down) {
                nativeCommand(action);
            }
            return;
        }
        nativeKey(action, down);
    }

    private void tap(ControlLayout.Control c) {
        press(c, true);
        press(c, false);
        performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
    }

    @Override
    public boolean onTouchEvent(MotionEvent ev) {
        if (editing) {
            return onEditTouch(ev);
        }
        if (gamepadHidden && ev.getActionMasked() == MotionEvent.ACTION_DOWN) {
            gamepadHidden = false;
            invalidate();
        }
        if (!inGame || cursorUi) {
            if ((consoleOpen || cursorUi) && ev.getActionMasked() == MotionEvent.ACTION_DOWN) {
                ControlLayout.Control c = controlAt(ev.getX(), ev.getY());
                if (c != null) {
                    tap(c);
                    return true;
                }
            }
            // Menus and console: the first finger is the mouse cursor, a tap is a left click.
            switch (ev.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    nativeMenuPointer(ev.getX(), ev.getY(), POINTER_DOWN);
                    break;
                case MotionEvent.ACTION_MOVE:
                    nativeMenuPointer(ev.getX(), ev.getY(), POINTER_MOVE);
                    break;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    nativeMenuPointer(ev.getX(), ev.getY(), POINTER_UP);
                    break;
            }
            return true;
        }
        int action = ev.getActionMasked();
        int index = ev.getActionIndex();
        switch (action) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN:
                pointerDown(ev.getPointerId(index), ev.getX(index), ev.getY(index));
                break;
            case MotionEvent.ACTION_MOVE:
                for (int i = 0; i < ev.getPointerCount(); i++) {
                    pointerMove(ev.getPointerId(i), ev.getX(i), ev.getY(i));
                }
                break;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_POINTER_UP:
                pointerUp(ev.getPointerId(index));
                break;
            case MotionEvent.ACTION_CANCEL:
                releaseAll();
                break;
        }
        invalidate();
        return true;
    }

    private void pointerDown(int id, float x, float y) {
        Pointer p = new Pointer();
        p.lastX = x;
        p.lastY = y;
        p.downTime = SystemClock.uptimeMillis();
        ControlLayout.Control c = controlAt(x, y);
        if (c != null) {
            p.role = ROLE_CONTROL;
            p.control = c;
            if (ControlLayout.MODE_TOGGLE.equals(c.mode)) {
                c.down = !c.down;
                press(c, c.down);
            } else if (ControlLayout.MODE_TAP.equals(c.mode)) {
                c.down = true; // fires on release so a long hold can open the editor instead
            } else {
                c.down = true;
                press(c, true);
            }
            performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
        } else if (x < getWidth() * layout.stickZone && !stickActive) {
            p.role = ROLE_STICK;
            stickActive = true;
            stickBaseX = stickKnobX = x;
            stickBaseY = stickKnobY = y;
            nativeSetMove(0, 0);
        } else {
            p.role = ROLE_LOOK;
        }
        pointers.put(id, p);
    }

    private void pointerMove(int id, float x, float y) {
        Pointer p = pointers.get(id);
        if (p == null) {
            return;
        }
        if (p.role == ROLE_STICK) {
            float dx = x - stickBaseX, dy = y - stickBaseY;
            float len = (float) Math.sqrt(dx * dx + dy * dy);
            if (len > stickRadius) {
                // drag the base along so the stick never needs recentering
                float excess = len - stickRadius;
                stickBaseX += dx / len * excess;
                stickBaseY += dy / len * excess;
                dx = x - stickBaseX;
                dy = y - stickBaseY;
            }
            stickKnobX = x;
            stickKnobY = y;
            nativeSetMove(dx / stickRadius, dy / stickRadius);
        } else if (p.role == ROLE_LOOK || (p.role == ROLE_CONTROL && p.control.looks)) {
            nativeAddLook((x - p.lastX) / density, (y - p.lastY) / density);
        }
        p.lastX = x;
        p.lastY = y;
    }

    private void pointerUp(int id) {
        Pointer p = pointers.get(id);
        if (p == null) {
            return;
        }
        if (p.role == ROLE_STICK) {
            stickActive = false;
            nativeSetMove(0, 0);
        } else if (p.role == ROLE_CONTROL) {
            ControlLayout.Control c = p.control;
            if (ControlLayout.MODE_TAP.equals(c.mode)) {
                c.down = false;
                if (SystemClock.uptimeMillis() - p.downTime >= LONG_PRESS_MS && listener != null) {
                    pointers.remove(id);
                    listener.onEditRequested();
                    return;
                }
                press(c, true);
                press(c, false);
            } else if (ControlLayout.MODE_HOLD.equals(c.mode) && c.down) {
                c.down = false;
                press(c, false);
            }
        }
        pointers.remove(id);
    }

    private boolean onEditTouch(MotionEvent ev) {
        switch (ev.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                ControlLayout.Control c = controlAt(ev.getX(), ev.getY());
                select(c);
                dragPointerId = ev.getPointerId(0);
                pinching = false;
                if (c != null) {
                    dragOffX = c.cx - ev.getX();
                    dragOffY = c.cy - ev.getY();
                }
                break;
            }
            case MotionEvent.ACTION_POINTER_DOWN:
                if (selected != null && ev.getPointerCount() >= 2) {
                    pinching = true;
                    pinchStartDist = spacing(ev);
                    pinchStartSize = selected.size;
                }
                break;
            case MotionEvent.ACTION_MOVE:
                if (selected == null) {
                    break;
                }
                if (pinching && ev.getPointerCount() >= 2) {
                    if (pinchStartDist > 10 * density) {
                        selected.size = clamp(pinchStartSize * spacing(ev) / pinchStartDist, 12, 120);
                    }
                } else {
                    int idx = ev.findPointerIndex(dragPointerId);
                    if (idx >= 0) {
                        selected.x = clamp((ev.getX(idx) + dragOffX - areaLeft) / areaWidth, 0, 1);
                        selected.y = clamp((ev.getY(idx) + dragOffY - areaTop) / areaHeight, 0, 1);
                    }
                }
                layoutControls();
                break;
            case MotionEvent.ACTION_POINTER_UP: {
                pinching = false;
                // keep dragging with whichever finger stays down
                int leaving = ev.getActionIndex();
                int remaining = leaving == 0 ? 1 : 0;
                if (remaining < ev.getPointerCount()) {
                    dragPointerId = ev.getPointerId(remaining);
                    if (selected != null) {
                        dragOffX = selected.cx - ev.getX(remaining);
                        dragOffY = selected.cy - ev.getY(remaining);
                    }
                }
                break;
            }
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                dragPointerId = -1;
                pinching = false;
                break;
        }
        invalidate();
        return true;
    }

    private static float spacing(MotionEvent ev) {
        float dx = ev.getX(0) - ev.getX(1), dy = ev.getY(0) - ev.getY(1);
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    private static float clamp(float v, float lo, float hi) {
        return v < lo ? lo : (v > hi ? hi : v);
    }

    private int alpha(int a) {
        return Math.max(0, Math.min(255, Math.round(a * layout.opacity)));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if (editing) {
            canvas.drawColor(Color.argb(110, 0, 0, 0));
            float zoneX = getWidth() * layout.stickZone;
            dashed.setColor(Color.argb(140, 255, 255, 255));
            canvas.drawLine(zoneX, 0, zoneX, getHeight(), dashed);
            text.setColor(Color.argb(160, 255, 255, 255));
            text.setTextSize(13 * density);
            canvas.drawText("move stick zone", zoneX / 2, getHeight() - safe.bottom - 24 * density, text);
            canvas.drawText("look zone", zoneX + (getWidth() - zoneX) / 2, getHeight() - safe.bottom - 24 * density, text);
        } else if (gamepadHidden) {
            return;
        } else if (inGame && !cursorUi) {
            if (stickActive) {
                fill.setColor(Color.argb(alpha(40), 255, 255, 255));
                canvas.drawCircle(stickBaseX, stickBaseY, stickRadius, fill);
                fill.setColor(Color.argb(alpha(120), 255, 255, 255));
                canvas.drawCircle(stickKnobX, stickKnobY, stickRadius * 0.4f, fill);
            } else {
                stroke.setColor(Color.argb(alpha(50), 255, 255, 255));
                float hx = safe.left + 110 * density, hy = getHeight() - safe.bottom - 110 * density;
                canvas.drawCircle(hx, hy, stickRadius, stroke);
            }
        }
        for (ControlLayout.Control c : layout.controls) {
            if (shownNow(c)) {
                drawControl(canvas, c);
            }
        }
    }

    private void drawControl(Canvas canvas, ControlLayout.Control c) {
        float fade = editing && !c.visible ? 0.35f : 1f;
        fill.setColor(c.down ? Color.argb(alpha((int) (110 * fade)), 255, 140, 0) : Color.argb(alpha((int) (28 * fade)), 0, 0, 0));
        canvas.drawCircle(c.cx, c.cy, c.r, fill);
        stroke.setColor(c.down ? Color.argb(alpha(220), 255, 170, 60) : Color.argb(alpha((int) (110 * fade)), 255, 255, 255));
        canvas.drawCircle(c.cx, c.cy, c.r, stroke);
        int iconColor = c.down ? Color.argb(alpha(255), 255, 200, 120) : Color.argb(alpha((int) (210 * fade)), 255, 255, 255);
        drawIcon(canvas, c, c.cx, c.cy, c.r * 0.5f, iconColor);
        if (editing && c == selected) {
            dashed.setColor(Color.argb(255, 255, 210, 60));
            canvas.drawCircle(c.cx, c.cy, c.r + 6 * density, dashed);
        }
    }

    private static int iconIndex(String name) {
        for (int i = 0; i < ICON_NAMES.length; i++) {
            if (ICON_NAMES[i].equals(name)) {
                return i;
            }
        }
        return ICON_NAMES.length - 1; // text
    }

    /** Icons are drawn in a unit box of half-size s around (cx, cy); coordinates below are in that unit space. */
    private void drawIcon(Canvas c, ControlLayout.Control control, float cx, float cy, float s, int color) {
        iconStroke.setColor(color);
        iconStroke.setStrokeWidth(Math.max(1.5f * density, s * 0.16f));
        iconFill.setColor(color);
        path.reset();
        switch (iconIndex(control.icon)) {
            case 0: // fire: crosshair
                c.drawCircle(cx, cy, s * 0.62f, iconStroke);
                line(c, cx, cy, s, 0, -1.0f, 0, -0.35f);
                line(c, cx, cy, s, 0, 0.35f, 0, 1.0f);
                line(c, cx, cy, s, -1.0f, 0, -0.35f, 0);
                line(c, cx, cy, s, 0.35f, 0, 1.0f, 0);
                c.drawCircle(cx, cy, s * 0.08f, iconFill);
                break;
            case 1: // aim: scope
                c.drawCircle(cx, cy, s * 0.85f, iconStroke);
                line(c, cx, cy, s, -0.85f, 0, 0.85f, 0);
                line(c, cx, cy, s, 0, -0.85f, 0, 0.85f);
                c.drawCircle(cx, cy, s * 0.22f, iconStroke);
                break;
            case 2: // jump: double up chevron
                chevron(c, cx, cy, s, 0, -0.35f, -1);
                chevron(c, cx, cy, s, 0, 0.35f, -1);
                break;
            case 3: // crouch: down chevron over a floor
                chevron(c, cx, cy, s, 0, -0.25f, 1);
                line(c, cx, cy, s, -0.8f, 0.6f, 0.8f, 0.6f);
                break;
            case 4: { // reload: circular arrow, arrowhead on the arc's tangent
                float r = s * 0.72f;
                float startDeg = 35f, sweepDeg = 275f;
                oval.set(cx - r, cy - r, cx + r, cy + r);
                c.drawArc(oval, startDeg, sweepDeg, false, iconStroke);
                double a = Math.toRadians(startDeg);
                float hx = cx + (float) Math.cos(a) * r;
                float hy = cy + (float) Math.sin(a) * r;
                path.reset();
                path.moveTo(hx + s * 0.34f, hy);
                path.lineTo(hx - s * 0.20f, hy - s * 0.26f);
                path.lineTo(hx - s * 0.20f, hy + s * 0.26f);
                path.close();
                c.save();
                c.rotate(startDeg - 90f, hx, hy); // point the head back along the arc
                c.drawPath(path, iconFill);
                c.restore();
                break;
            }
            case 5: // use: door with handle
                path.moveTo(cx - s * 0.55f, cy + s * 0.9f);
                path.lineTo(cx - s * 0.55f, cy - s * 0.9f);
                path.lineTo(cx + s * 0.55f, cy - s * 0.9f);
                path.lineTo(cx + s * 0.55f, cy + s * 0.9f);
                c.drawPath(path, iconStroke);
                c.drawCircle(cx + s * 0.25f, cy + s * 0.05f, s * 0.12f, iconFill);
                break;
            case 6: // run: double right chevron
                sideChevron(c, cx, cy, s, -0.3f, 1);
                sideChevron(c, cx, cy, s, 0.3f, 1);
                break;
            case 7: // grenade: body, lever, pin ring
                c.drawCircle(cx, cy + s * 0.2f, s * 0.6f, iconStroke);
                line(c, cx, cy, s, -0.2f, -0.45f, 0.2f, -0.45f);
                line(c, cx, cy, s, 0.1f, -0.45f, 0.1f, -0.75f);
                c.drawCircle(cx - s * 0.35f, cy - s * 0.75f, s * 0.2f, iconStroke);
                break;
            case 8: // heal: medical cross
                path.addRect(cx - s * 0.22f, cy - s * 0.8f, cx + s * 0.22f, cy + s * 0.8f, Path.Direction.CW);
                path.addRect(cx - s * 0.8f, cy - s * 0.22f, cx + s * 0.8f, cy + s * 0.22f, Path.Direction.CW);
                path.setFillType(Path.FillType.WINDING);
                c.drawPath(path, iconFill);
                break;
            case 9: // light: flashlight with beam
                path.moveTo(cx - s * 0.9f, cy - s * 0.2f);
                path.lineTo(cx - s * 0.2f, cy - s * 0.2f);
                path.lineTo(cx + s * 0.1f, cy - s * 0.45f);
                path.lineTo(cx + s * 0.1f, cy + s * 0.45f);
                path.lineTo(cx - s * 0.2f, cy + s * 0.2f);
                path.lineTo(cx - s * 0.9f, cy + s * 0.2f);
                path.close();
                c.drawPath(path, iconStroke);
                line(c, cx, cy, s, 0.35f, -0.5f, 0.9f, -0.8f);
                line(c, cx, cy, s, 0.4f, 0, 0.95f, 0);
                line(c, cx, cy, s, 0.35f, 0.5f, 0.9f, 0.8f);
                break;
            case 10: // next
                sideChevron(c, cx, cy, s, 0.1f, 1);
                break;
            case 11: // prev
                sideChevron(c, cx, cy, s, -0.1f, -1);
                break;
            case 12: // score: bar chart
                line(c, cx, cy, s, -0.55f, 0.7f, -0.55f, 0.1f);
                line(c, cx, cy, s, 0, 0.7f, 0, -0.7f);
                line(c, cx, cy, s, 0.55f, 0.7f, 0.55f, -0.25f);
                break;
            case 13: // menu: three lines
                line(c, cx, cy, s, -0.7f, -0.5f, 0.7f, -0.5f);
                line(c, cx, cy, s, -0.7f, 0, 0.7f, 0);
                line(c, cx, cy, s, -0.7f, 0.5f, 0.7f, 0.5f);
                break;
            case 14: // console: prompt ">_"
                path.moveTo(cx - s * 0.75f, cy - s * 0.45f);
                path.lineTo(cx - s * 0.2f, cy);
                path.lineTo(cx - s * 0.75f, cy + s * 0.45f);
                c.drawPath(path, iconStroke);
                line(c, cx, cy, s, 0.05f, 0.5f, 0.8f, 0.5f);
                break;
            case 15: // keyboard: key caps
                oval.set(cx - s * 0.9f, cy - s * 0.55f, cx + s * 0.9f, cy + s * 0.55f);
                c.drawRoundRect(oval, s * 0.15f, s * 0.15f, iconStroke);
                for (int k = 0; k < 4; k++) {
                    c.drawCircle(cx + (-0.54f + k * 0.36f) * s, cy - 0.18f * s, s * 0.06f, iconFill);
                }
                line(c, cx, cy, s, -0.45f, 0.25f, 0.45f, 0.25f);
                break;
            default: { // text: the label, or the start of the action when there is none
                String label = control.label != null && !control.label.isEmpty() ? control.label : control.action;
                if (label == null || label.isEmpty()) {
                    label = "?";
                }
                if (label.length() > 4) {
                    label = label.substring(0, 4);
                }
                text.setColor(color);
                text.setTextSize(s * (label.length() <= 2 ? 1.0f : 0.72f));
                canvas(c, label, cx, cy);
                break;
            }
        }
    }

    private void canvas(Canvas c, String label, float cx, float cy) {
        Paint.FontMetrics fm = text.getFontMetrics();
        c.drawText(label, cx, cy - (fm.ascent + fm.descent) / 2, text);
    }

    private void line(Canvas c, float cx, float cy, float s, float x0, float y0, float x1, float y1) {
        c.drawLine(cx + x0 * s, cy + y0 * s, cx + x1 * s, cy + y1 * s, iconStroke);
    }

    /** Vertical chevron; dir -1 points up, 1 points down. */
    private void chevron(Canvas c, float cx, float cy, float s, float ox, float oy, int dir) {
        path.reset();
        path.moveTo(cx + (ox - 0.65f) * s, cy + (oy - 0.3f * dir) * s);
        path.lineTo(cx + ox * s, cy + (oy + 0.3f * dir) * s);
        path.lineTo(cx + (ox + 0.65f) * s, cy + (oy - 0.3f * dir) * s);
        c.drawPath(path, iconStroke);
    }

    /** Horizontal chevron; dir 1 points right, -1 points left. */
    private void sideChevron(Canvas c, float cx, float cy, float s, float ox, int dir) {
        path.reset();
        path.moveTo(cx + (ox - 0.3f * dir) * s, cy - 0.65f * s);
        path.lineTo(cx + (ox + 0.3f * dir) * s, cy);
        path.lineTo(cx + (ox - 0.3f * dir) * s, cy + 0.65f * s);
        c.drawPath(path, iconStroke);
    }
}
