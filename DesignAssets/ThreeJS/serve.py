from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(ROOT),**kwargs)
 def do_POST(self):
  name=self.path.removeprefix('/export/')
  if not self.path.startswith('/export/') or not re.fullmatch(r'(digit-[0-9]|colon)\.(png|glb)|manifest\.json',name):self.send_error(400);return
  size=int(self.headers.get('Content-Length','0'))
  if not 0<size<8000000:self.send_error(413);return
  folder=ROOT if name=='manifest.json' else ROOT/('models' if name.endswith('.glb') else 'png');folder.mkdir(exist_ok=True)
  (folder/name).write_bytes(self.rfile.read(size));self.send_response(200);self.end_headers();self.wfile.write(b'OK')
print('Restricted Three.js preview: http://127.0.0.1:8770',flush=True)
ThreadingHTTPServer(('127.0.0.1',8770),Handler).serve_forever()
