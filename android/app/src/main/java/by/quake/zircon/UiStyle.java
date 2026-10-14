package by.quake.zircon;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.graphics.drawable.StateListDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.List;

/** Shared look for the launcher, settings and control editor: dark surfaces, rounded pill buttons, one accent. */
final class UiStyle {

    static final int BG = 0xFF0E1014;
    static final int SURFACE = 0xFF171A20;
    static final int SURFACE_HIGH = 0xFF232830;
    static final int OUTLINE = 0x33FFFFFF;
    static final int TEXT = 0xFFF1F3F6;
    static final int TEXT_DIM = 0xFF98A1AD;
    static final int WARNING = 0xFFFFB35C;

    enum Kind { PRIMARY, SECONDARY, GHOST }

    /** dark dialog with the game's accent; the platform themes are grey with a teal accent */
    static final int DIALOG_THEME = R.style.AppDialog;

    /** keeps content clear of the navigation bar and cutout in these fullscreen activities, on top of the view's own padding */
    static void applyInsets(View v) {
        final int l = v.getPaddingLeft(), t = v.getPaddingTop(), r = v.getPaddingRight(), b = v.getPaddingBottom();
        v.setOnApplyWindowInsetsListener((view, insets) -> {
            view.setPadding(l + insets.getSystemWindowInsetLeft(), t + insets.getSystemWindowInsetTop(),
                r + insets.getSystemWindowInsetRight(), b + insets.getSystemWindowInsetBottom());
            return insets;
        });
        v.requestApplyInsets();
    }

    static void spinner(android.widget.Spinner s) {
        Context c = s.getContext();
        GradientDrawable bg = new GradientDrawable();
        bg.setCornerRadius(dp(c, 12));
        bg.setColor(SURFACE_HIGH);
        bg.setStroke(Math.max(1, dp(c, 1)), OUTLINE);
        s.setBackground(bg);
        s.setPadding(dp(c, 6), dp(c, 2), dp(c, 6), dp(c, 2));
        s.setPopupBackgroundDrawable(card(c));
    }

    private static final Typeface MEDIUM = Typeface.create("sans-serif-medium", Typeface.NORMAL);

    private UiStyle() {
    }

    static int accent() {
        return GameProfile.get().accentColor();
    }

    static Button button(Context c, String label, Kind kind, View.OnClickListener onClick) {
        Button b = new Button(c, null, 0, 0);
        b.setText(label);
        b.setOnClickListener(onClick);
        style(b, kind, false);
        return b;
    }

    /** smaller variant for toolbars */
    static Button chip(Context c, String label, Kind kind, View.OnClickListener onClick) {
        Button b = new Button(c, null, 0, 0);
        b.setText(label);
        b.setOnClickListener(onClick);
        style(b, kind, true);
        return b;
    }

    /** restyle an existing button, for toggle rows that show the selected item in the accent */
    static void applyKind(Button b, Kind kind, boolean compact) {
        style(b, kind, compact);
    }

    private static void style(Button b, Kind kind, boolean compact) {
        Context c = b.getContext();
        int accent = accent();
        int fill, fillDisabled, text, stroke;
        switch (kind) {
            case PRIMARY:
                fill = accent;
                fillDisabled = withAlpha(accent, 0x55);
                text = onColor(accent);
                stroke = 0;
                break;
            case SECONDARY:
                fill = SURFACE_HIGH;
                fillDisabled = withAlpha(SURFACE_HIGH, 0x88);
                text = TEXT;
                stroke = OUTLINE;
                break;
            default:
                fill = Color.TRANSPARENT;
                fillDisabled = Color.TRANSPARENT;
                text = TEXT_DIM;
                stroke = 0;
                break;
        }
        int height = dp(c, compact ? 38 : 46);

        GradientDrawable shape = new GradientDrawable();
        shape.setCornerRadius(height / 2f);
        shape.setColor(new ColorStateList(
            new int[][] { { -android.R.attr.state_enabled }, {} },
            new int[] { fillDisabled, fill }));
        if (stroke != 0) {
            shape.setStroke(Math.max(1, dp(c, 1)), stroke);
        }
        GradientDrawable mask = new GradientDrawable();
        mask.setCornerRadius(height / 2f);
        mask.setColor(Color.WHITE);
        b.setBackground(new RippleDrawable(ColorStateList.valueOf(kind == Kind.PRIMARY ? 0x40FFFFFF : 0x26FFFFFF), shape, mask));

        b.setTextColor(new ColorStateList(
            new int[][] { { -android.R.attr.state_enabled }, {} },
            new int[] { withAlpha(text, 0x66), text }));
        b.setAllCaps(false);
        b.setSingleLine(true);
        b.setMaxLines(1);
        b.setTypeface(MEDIUM);
        b.setTextSize(compact ? 14 : 15);
        b.setLetterSpacing(0.01f);
        b.setGravity(Gravity.CENTER);
        b.setMinHeight(height);
        b.setMinimumHeight(height);
        b.setMinWidth(0);
        b.setMinimumWidth(0);
        int padH = dp(c, compact ? 14 : 22);
        b.setPadding(padH, 0, padH, 0);
        b.setStateListAnimator(null);
        b.setElevation(0);
    }

    static void field(EditText e) {
        Context c = e.getContext();
        GradientDrawable bg = new GradientDrawable();
        bg.setCornerRadius(dp(c, 12));
        bg.setColor(SURFACE_HIGH);
        bg.setStroke(Math.max(1, dp(c, 1)), OUTLINE);
        e.setBackground(bg);
        e.setTextColor(TEXT);
        e.setHintTextColor(TEXT_DIM);
        e.setTextSize(15);
        e.setPadding(dp(c, 14), dp(c, 11), dp(c, 14), dp(c, 11));
    }

    static Drawable card(Context c) {
        GradientDrawable bg = new GradientDrawable();
        bg.setCornerRadius(dp(c, 18));
        bg.setColor(SURFACE);
        return bg;
    }

    static TextView title(Context c, String text, int sp) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(sp);
        t.setTextColor(TEXT);
        t.setTypeface(MEDIUM);
        return t;
    }

    static TextView body(Context c, String text, int sp, int color) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(sp);
        t.setTextColor(color);
        t.setLineSpacing(0, 1.15f);
        return t;
    }

    static void tint(CheckBox cb) {
        cb.setButtonTintList(new ColorStateList(
            new int[][] { { android.R.attr.state_checked }, {} },
            new int[] { accent(), TEXT_DIM }));
        cb.setTextColor(TEXT);
        cb.setTextSize(15);
    }

    static void tint(SeekBar bar) {
        bar.setProgressTintList(ColorStateList.valueOf(accent()));
        bar.setThumbTintList(ColorStateList.valueOf(accent()));
        bar.setProgressBackgroundTintList(ColorStateList.valueOf(0x55FFFFFF));
    }

    static void list(ListView list) {
        list.setDivider(new ColorDrawable(Color.TRANSPARENT));
        list.setDividerHeight(dp(list.getContext(), 4));
        list.setSelector(new ColorDrawable(Color.TRANSPARENT));
        list.setVerticalScrollBarEnabled(false);
    }

    /** rows that highlight with the accent when activated (single-choice ListView) */
    static <T> ArrayAdapter<T> listAdapter(Context c, List<T> items) {
        return new ArrayAdapter<T>(c, 0, items) {
            @Override
            public View getView(int position, View convertView, ViewGroup parent) {
                TextView t;
                if (convertView instanceof TextView) {
                    t = (TextView) convertView;
                } else {
                    t = new TextView(c);
                    t.setTextSize(16);
                    t.setTypeface(MEDIUM);
                    t.setSingleLine(true);
                    t.setPadding(dp(c, 18), dp(c, 13), dp(c, 18), dp(c, 13));
                    t.setBackground(rowBackground(c));
                    t.setTextColor(new ColorStateList(
                        new int[][] { { android.R.attr.state_activated }, {} },
                        new int[] { TEXT, TEXT_DIM }));
                }
                t.setText(String.valueOf(getItem(position)));
                return t;
            }
        };
    }

    private static Drawable rowBackground(Context c) {
        float r = dp(c, 12);
        GradientDrawable activated = new GradientDrawable();
        activated.setCornerRadius(r);
        activated.setColor(withAlpha(accent(), 0x40));
        activated.setStroke(Math.max(1, dp(c, 1)), withAlpha(accent(), 0x99));
        GradientDrawable pressed = new GradientDrawable();
        pressed.setCornerRadius(r);
        pressed.setColor(0x14FFFFFF);
        StateListDrawable states = new StateListDrawable();
        states.addState(new int[] { android.R.attr.state_activated }, activated);
        states.addState(new int[] { android.R.attr.state_pressed }, pressed);
        states.addState(new int[] {}, new ColorDrawable(Color.TRANSPARENT));
        return states;
    }

    static int withAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | (alpha << 24);
    }

    /** readable text color on top of a filled accent */
    private static int onColor(int background) {
        double lum = (0.299 * Color.red(background) + 0.587 * Color.green(background) + 0.114 * Color.blue(background)) / 255;
        return lum > 0.62 ? 0xFF15171B : Color.WHITE;
    }

    static int dp(Context c, int v) {
        return Math.round(v * c.getResources().getDisplayMetrics().density);
    }
}
