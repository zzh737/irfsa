"""Dark palette shared by every Radio Studio window (plots already use the navy PLOT tones)."""
import sys

BG = '#0e1726'          # window body, around the cards and panes
SURFACE = '#16223a'     # cards, tab pages, panels (was white)
FIELD = '#0f1a2c'       # entry / text backgrounds
RAISED = '#22324d'      # plain buttons, scrollbar thumbs, progress tracks
BORDER = '#2a3a55'
HEADER = '#0a1220'
TEXT = '#dbe5f2'
MUTED = '#8597b0'
DISABLED = '#56667e'
BLUE = '#3d7bfd'        # primary buttons, progress fill
ACCENT = '#6aa1ff'      # blue used as a text colour
OK = '#3ccfa8'
WARN = '#e5a740'
CRITICAL = '#ff8a3d'    # orange-red: proceeds, but the result will not match the plan
ERROR = '#ff6b7d'


def dark_titlebar(window):
    """Windows 10 1809+/11: ask DWM for a dark caption. No-op elsewhere or on failure."""
    if sys.platform != 'win32':
        return
    try:
        import ctypes
        window.update_idletasks()
        hwnd = ctypes.windll.user32.GetParent(window.winfo_id())
        value = ctypes.c_int(1)
        for attribute in (20, 19):  # DWMWA_USE_IMMERSIVE_DARK_MODE, pre-20H1 value
            if not ctypes.windll.dwmapi.DwmSetWindowAttribute(hwnd, attribute, ctypes.byref(value), ctypes.sizeof(value)):
                break
    except Exception:
        pass
