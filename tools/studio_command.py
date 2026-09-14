"""Send a developer command directly to the preview Studio command bar."""
import ctypes
import sys
import time
u=ctypes.windll.user32
class Point(ctypes.Structure):
    _fields_=[('x',ctypes.c_long),('y',ctypes.c_long)]
class Rect(ctypes.Structure):
    _fields_=[('left',ctypes.c_long),('top',ctypes.c_long),('right',ctypes.c_long),('bottom',ctypes.c_long)]
u.ChildWindowFromPointEx.argtypes=[ctypes.c_void_p,Point,ctypes.c_uint]
u.ChildWindowFromPointEx.restype=ctypes.c_void_p
windows=[]
CALLBACK=ctypes.WINFUNCTYPE(ctypes.c_bool,ctypes.c_void_p,ctypes.c_void_p)
def visit(hwnd,_):
    title=ctypes.create_unicode_buffer(1000)
    u.GetWindowTextW(hwnd,title,1000)
    if 'ReferencePreview.rbxlx - Roblox Studio' in title.value and u.IsWindowVisible(hwnd): windows.append(hwnd)
    return True
u.EnumWindows(CALLBACK(visit),0)
if not windows: raise SystemExit('Preview Studio not found')
hwnd=windows[0]
rect=Rect(); u.GetWindowRect(hwnd,ctypes.byref(rect))
run_only=sys.argv[1]=='--run'
screen_x,screen_y=(rect.right-60,rect.bottom-(int(sys.argv[2]) if len(sys.argv)>2 else 88)) if run_only else (rect.left+350,rect.bottom-51)
target=hwnd
for _ in range(12):
    pt=Point(screen_x,screen_y); u.ScreenToClient(target,ctypes.byref(pt))
    child=u.ChildWindowFromPointEx(target,pt,3)
    if not child or child==target: break
    target=child
pt=Point(screen_x,screen_y); u.ScreenToClient(target,ctypes.byref(pt))
position=(pt.y<<16)|(pt.x&0xffff)
u.PostMessageW(target,0x201,1,position); u.PostMessageW(target,0x202,0,position)
if run_only:
    print('Clicked command bar Run')
    raise SystemExit(0)
time.sleep(.2)
for char in sys.argv[1]: u.PostMessageW(target,0x102,ord(char),1)
time.sleep(.2)
u.PostMessageW(target,0x100,0x0d,0x001c0001); u.PostMessageW(target,0x101,0x0d,0xc01c0001)
print('Command sent to preview command bar')
