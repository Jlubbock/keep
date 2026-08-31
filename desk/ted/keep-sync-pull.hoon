::  keep-sync-pull — import everything new from one substack publication.
::
::    arg: (unit [name=@tas url=@t since=@da]) — sub name, base url, newest
::    post_date already had.  every post lands as its own %ingest poke as we
::    go, so a run that dies keeps what it reached and the next one resumes.
::    result: how many landed.
::
/-  spider, ks=keep-sync
/+  strandio, sk=substack, io=substack-io
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
=/  [name=@tas url=@t since=@da]
  (need !<((unit [name=@tas url=@t since=@da]) arg))
;<  entries=(list meta:ks)  bind:m  (fetch-archive:io url since)
::  oldest first: `last` then grows monotonically, which is what makes
::  resumption after a mid-run failure safe
=/  work=(list meta:ks)
  %-  flop
  (skim `(list meta:ks)`entries |=(e=meta:ks (gth wen.e since)))
=/  count=@ud  0
|-  ^-  form:m
?~  work  (pure:m !>(count))
;<  ~  bind:m  (sleep:strandio (div ~s1 4))
;<  pj=json  bind:m  (fetch-json:io (rap 3 url '/api/v1/posts/' slug.i.work ~))
=/  p=(unit post:ks)  (post-md:sk pj)
?~  p  $(work t.work)
;<  ~  bind:m
  %+  poke-our:strandio  %keep-sync
  keep-sync-action+!>(`action:ks`[%ingest name u.p])
$(work t.work, count +(count))
