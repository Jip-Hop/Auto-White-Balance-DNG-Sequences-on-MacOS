# Auto-White-Balance-DNG-Sequences-on-MacOS
A MacOS Finder Workflow to Auto White Balance CinemaDNG sequences. Useful for converted Magic Lantern RAW footage (MLV).

## Installation
Download [DNG White Balance.workflow.zip](https://github.com/Jip-Hop/Auto-White-Balance-DNG-Sequences-on-MacOS/raw/master/DNG%20White%20Balance.workflow.zip) and unzip and install `DNG White Balance.workflow`. It will be added to the `Quick Actions` and `Services` section when right clicking a folder (or multiple Folders) in the Finder. You don't need the `awb.command`, it's embedded within the `DNG White Balance.workflow` file.

## Usage
In the Finder, select folders with CinemaDNG sequences exported from e.g. [MLV App](https://github.com/ilia3101/MLV-App). Right click and choose `DNG White Balance` in the `Quick Actions` or `Services` dropdown. Accept to install the dependencies if asked, and wait for the processing to finish.

## Why
I shoot with my EOS M, with Magic Lantern, in Auto White Balance mode. But the AWB values aren't stored in the MLV clips. Since it's RAW video, it's possible to do white balancing in post production without quality loss. But since I don't manually white balance in camera, and AWB values aren't applied, the white balance for all of my shots is way off and manual correction takes a lot of time. This workflow quickly gives me a way better starting off point and I don't need to tweak the white balance as much in DaVinci Resolve.

## How
From each DNG sequence, 8 frames are analysed with [dcraw](https://www.dechifro.org/dcraw/). These AWB values are averaged into a single estimate white balance for the entire sequence. This value is then applied to all the frames in the sequence using [exiv2](https://www.exiv2.org).

## Porting
The awb.command contains the core functionality. It should be relatively easy to port to Linux (remove the part about installing dependencies with brew and install the dependencies manually). Probably would work under the Windows Subsystem for Linux too.

## Thanks to
[Danne](http://github.com/dannephoto) and everyone credited in the [Switch](https://www.magiclantern.fm/forum/index.php?topic=15108.0) project. They figured out how to Auto White Balance DNG sequences with Switch. It does much more too, I recommend you check it out. I ported the AWB portion of Switch into this Workflow, so anyone can apply AWB to DNG sequences, regardless of which tool or camera was used to make the DNG files.
