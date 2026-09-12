::  keep-sync-about — does a publication's /about page name this ship?
::
::    arg: (unit [who=@p url=@t])     result: ?
::
/-  spider
/+  strandio, sk=substack, io=substack-io
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
=/  [who=@p url=@t]  (need !<((unit [who=@p url=@t]) arg))
;<  page=cord  bind:m  (fetch-html:io (rap 3 url '/about' ~))
(pure:m !>((mentions:sk who page)))
