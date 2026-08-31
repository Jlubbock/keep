::  keep-sync-scan — walk a publication's whole archive and report what a
::  track would import. no bodies are fetched.
::
::    arg: (unit url=@t)      result: scan:ks
::
/-  spider, ks=keep-sync
/+  strandio, io=substack-io
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
=/  url=@t  (need !<((unit @t) arg))
;<  entries=(list meta:ks)  bind:m  (fetch-archive:io url *@da)
?~  entries
  (pure:m !>(`scan:ks`[0 0 0 *@da *@da]))
=/  es=(list meta:ks)  `(list meta:ks)`entries
=/  n=@ud     (lent es)
=/  free=@ud  (lent (skim es |=(e=meta:ks =('everyone' aud.e))))
(pure:m !>(`scan:ks`[n free (sub n free) wen:(rear es) wen.i.entries]))
