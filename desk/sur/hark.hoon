::  landscape's hark types, vendored. a local poke carries our vase straight
::  to %hark, so these need only NEST into the real sur — same shapes, same
::  faces. nest:groups is inlined to keep the groups desk out of our build.
::
|%
+$  flag  (pair ship term)
+$  nest  (pair dude:gall flag)
+$  id    @uvH
::
+$  rope
  $:  gop=(unit flag)
      can=(unit nest)
      des=desk
      ted=path
  ==
::
+$  content
  $@  @t
  $%  [%ship p=ship]
      [%emph p=cord]
  ==
::
+$  button
  $:  title=cord
      handler=path
  ==
::
+$  yarn
  $:  =id
      rop=rope
      tim=time
      con=(list content)
      wer=path
      but=(unit button)
  ==
::
+$  new-yarn
  $:  all=?
      desk=?
      rop=rope
      con=(list content)
      wer=path
      but=(unit button)
  ==
::
+$  seam
  $%  [%group =flag]
      [%desk =desk]
      [%all ~]
  ==
::
+$  action
  $%  [%add-yarn all=? desk=? =yarn]
      [%saw-seam =seam]
      [%saw-rope =rope]
  ==
::
+$  action-1
  $%  [%new-yarn new-yarn]
      action
  ==
--
