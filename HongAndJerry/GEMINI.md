# Project Plan: 3-Track Vertical Video Editor

## 1. Core Concept
- **Goal:** An app to create a single video where three independent video clips play simultaneously in a vertical split-screen layout.
- **Primary Template:** The initial development will focus on a 1x3 vertical template (three videos stacked vertically).

## 2. UI/UX Breakdown
- **Main Screen:** Divided into two sections:
    - **Top (Video Preview):** A preview area showing the three videos playing at the same time in the 1x3 layout. The order of the tracks in the editor determines the vertical position of the videos.
    - **Bottom (Timeline Editor):** An editor panel with three distinct tracks.
- **Key Interactions:**
    - **Playback:** The playhead (a vertical bar) is fixed in the center of the editor. During playback, the timeline tracks scroll from right to left underneath the playhead.
    - **Trimming:** Users can trim each video clip by dragging handles at the beginning and end of each track.
    - **Reordering:** Users can long-press and drag a track to change its vertical order, which will correspond to a change in the video's position in the preview layout.
    - **Zoom:** Pinch-to-zoom functionality for the timeline is **not** required.

## 3. Technical Specifications
- **Final Video Duration:** The total length of the final exported video will be equal to the length of the longest trimmed clip. Shorter clips will end and freeze on their last frame until the longest clip finishes.
- **Audio Handling:** The audio from all three video tracks will be mixed together and play simultaneously in the final video.
- **Track Representation:** Each track in the timeline editor should be visualized using a sequence of thumbnails extracted from the source video.

## 4. Architecture (SwiftUI Implementation)
- **State Management:** Utilize the modern SwiftUI Observation framework (iOS 17+).
- **`VideoViewModel` (@Observable):**
    - A single source of truth, marked with the `@Observable` macro.
    - Manages an array of `VideoSegment` objects.
    - Contains all business logic for trimming, reordering, and video processing.
    - Responsible for loading initial video assets (`video1`, `video2`, `video3`) into `VideoSource` models and creating initial `VideoSegment` states.
- **`ContentView` (Main Container):**
    - Instantiates and owns the `VideoViewModel` using `@State`:
      ```swift
      @State private var viewModel = VideoViewModel()
      ```
    - Composes the main UI by arranging `VideoPlayer` and `VideoEditor` views.
    - Passes the `viewModel` instance down to its children.
- **`VideoPlayer` & `VideoEditor` (Child Views):**
    - Receive the `viewModel` as a simple `let` constant.
    - Do not require `@ObservedObject` or other property wrappers.
    - SwiftUI automatically tracks dependencies and updates the view only when necessary.

## 5. Project File Structure

```
HongAndJerry/
├───HongAndJerry/
│   ├───ContentView.swift
│   ├───HongAndJerryApp.swift
│   ├───Assets.xcassets/
│   │   ├───Contents.json
│   │   ├───AccentColor.colorset/
│   │   │   └───Contents.json
│   │   └───AppIcon.appiconset/
│   │       └───Contents.json
│   ├───Files/
│   │   ├───video1.MP4
│   │   ├───video2.MOV
│   │   └───video3.MOV
│   ├───Model/
│   │   ├───VideoSegment.swift
│   │   └───VideoSource.swift
│   ├───Preview Content/
│   │   └───Preview Assets.xcassets/
│   │       └───Contents.json
│   ├───View/
│   │   ├───VideoEditor/
│   │   │   └───VideoEditor.swift
│   │   └───VideoPlayer/
│   │       ├───VideoPlayer.swift
│   │       ├───VideoUIView.swift
│   │       └───VideoView.swift
│   └───ViewModel/
│       └───VideoViewModel.swift
└───HongAndJerry.xcodeproj/
    ├───project.pbxproj
    └───project.xcworkspace/
```

## 6. Communication Rules
- To save tokens, please answer in English.