"""Local Studio window controls and native screenshots for visual iteration."""
import argparse
import ctypes
import time
from pathlib import Path
from PIL import ImageGrab

parser = argparse.ArgumentParser()
parser.add_argument('action', choices=['show', 'play', 'stop', 'capture', 'click'])
parser.add_argument('--x',type=int,default=112)
parser.add_argument('--y',type=int,default=61)
parser.add_argument('--output', default='build/gauntlet/current.png')
parser.add_argument('--title', default='ReferencePreview')
args = parser.parse_args()
u = ctypes.windll.user32
windows = []
CALLBACK = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
def visit(hwnd, _):
    length = u.GetWindowTextLengthW(hwnd)
    title = ctypes.create_unicode_buffer(length + 1)
    u.GetWindowTextW(hwnd, title, length + 1)
    if 'Roblox Studio' in title.value and args.title in title.value:
        windows.append((hwnd, title.value))
    return True
u.EnumWindows(CALLBACK(visit), 0)
if not windows:
    raise SystemExit('No Studio window found')
foreground=u.GetForegroundWindow()
hwnd,title=next((item for item in windows if item[0]==foreground),windows[0])
u.ShowWindow(hwnd, 3)
u.SetForegroundWindow(hwnd)
time.sleep(.5)
if args.action in ('play', 'stop', 'capture', 'click'):
    current_thread = ctypes.windll.kernel32.GetCurrentThreadId()
    foreground_thread = u.GetWindowThreadProcessId(u.GetForegroundWindow(), None)
    u.AttachThreadInput(current_thread, foreground_thread, True)
    u.SetForegroundWindow(hwnd)
    u.SetFocus(hwnd)
    u.AttachThreadInput(current_thread, foreground_thread, False)
    time.sleep(.2)
    if u.GetForegroundWindow() != hwnd or args.action=='click':
        # Qt accepts a directed shortcut event without changing another application's focus.
        if args.action in ('play','stop','click'):
            screen_x,screen_y=(args.x,args.y) if args.action=='click' else (112 if args.action=='play' else 189,61)
            class Point(ctypes.Structure):
                _fields_=[('x',ctypes.c_long),('y',ctypes.c_long)]
            u.ChildWindowFromPointEx.argtypes=[ctypes.c_void_p,Point,ctypes.c_uint]
            u.ChildWindowFromPointEx.restype=ctypes.c_void_p
            target=hwnd
            for _ in range(12):
                pt=Point(screen_x,screen_y)
                u.ScreenToClient(target,ctypes.byref(pt))
                child=u.ChildWindowFromPointEx(target,pt,3)
                if not child or child==target: break
                target=child
            pt=Point(screen_x,screen_y)
            u.ScreenToClient(target,ctypes.byref(pt))
            position=(pt.y<<16)|(pt.x&0xffff)
            u.PostMessageW(target,0x201,1,position)
            u.PostMessageW(target,0x202,0,position)
            print('Clicked Studio '+args.action+' control directly')
            raise SystemExit(0)
        raise SystemExit(f'Could not focus Studio {hwnd:x}; foreground {u.GetForegroundWindow():x}; no keyboard input sent')
    if args.action in ('play', 'stop'):
        if args.action == 'stop': u.keybd_event(0x10, 0, 0, 0)
        u.keybd_event(0x74, 0, 0, 0)
        time.sleep(.1)
        u.keybd_event(0x74, 0, 2, 0)
        if args.action == 'stop': u.keybd_event(0x10, 0, 2, 0)
if args.action == 'capture':
    class Rect(ctypes.Structure):
        _fields_ = [('left', ctypes.c_long), ('top', ctypes.c_long), ('right', ctypes.c_long), ('bottom', ctypes.c_long)]
    rect = Rect()
    u.GetWindowRect(hwnd, ctypes.byref(rect))
    path = Path(args.output)
    path.parent.mkdir(exist_ok=True, parents=True)
    time.sleep(.3)
    ImageGrab.grab(bbox=(max(0,rect.left),max(0,rect.top),rect.right,rect.bottom)).save(path)
    print(path.resolve())
print(title)
