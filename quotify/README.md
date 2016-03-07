# Quotify

Based on a concept I saw on Reddit - download an image from r/Earthporn and overlay a quote from /ShowerThoughts.  I decided to give it a shot and when deciding what language to do it in thought it was a good opportunity to try something new - hence Powershell.

This script downloads a random image from the top of a bunch of subreddits (Earthporn, Breathless, etc), scales it to fit 1920x1280, then overlays a quote from r/ShowerThoughts.  The image is output to the desktop by default, but the output folder can also be set via the "-dir" parameter, e.g.:

quotify.ps1 -dir ..\

##Known issues:

- Small images aren't handled well, need to be scaled up