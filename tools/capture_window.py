"""Capture only Studio's GPU window, including when another window covers it."""
import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'.tools/capture'))
from windows_capture import WindowsCapture, Frame, InternalCaptureControl
output = sys.argv[1] if len(sys.argv)>1 else 'build/gauntlet/current.png'
title = sys.argv[2] if len(sys.argv)>2 else 'GhostlightHollow-ReferencePreview.rbxlx - Roblox Studio'
capture = WindowsCapture(cursor_capture=False, draw_border=False, window_name=title)
started=time.monotonic()
frames=0
last_saved=0
@capture.event
def on_frame_arrived(frame: Frame, capture_control: InternalCaptureControl):
    global frames, last_saved
    frames+=1
    now=time.monotonic()
    if now-last_saved>.5:
        frame.save_as_image(output)
        last_saved=now
    if now-started>8:
        capture_control.stop()
@capture.event
def on_closed():
    pass
control=capture.start_free_threaded()
time.sleep(10)
if not control.is_finished(): control.stop()
print(output)
