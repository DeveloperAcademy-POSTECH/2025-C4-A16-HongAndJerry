# Project Plan: 3-Track Vertical Video Editor

## 1. Core Concept
- **Goal:** An app to create a single video where three independent video clips play simultaneously in a vertical split-screen layout.
- **Primary Template:** The initial development will focus on a 1x3 vertical template (three videos stacked vertically).

## 2. UI/UX Breakdown
- **Main Screen:** Divided into two sections:
    - **Top (Video Preview):** A preview area showing the three videos playing at the same time in the 1x3 layout. The order of the tracks in the editor determines the vertical position of the videos.
    - **Bottom (Timeline Editor):** An editor panel that includes:
    - **Time Display:** A text overlay fixed to the top-left corner, showing the current playback time and total duration in "MM:SS / MM:SS" format. This display does not scroll with the timeline.
    - **Timeline:** A scrollable area composed of two main vertical components:
        - **Time Ruler:** A horizontally scrollable ruler displayed at the top of the editor. It shows time markers (e.g., "0s", "10s", "20s") with dots in between. The interval between markers is dynamically calculated based on the total video duration. The "0s" marker aligns perfectly with the central playhead at the start.
        - **Video Tracks:** Three distinct tracks stacked vertically below the time ruler.
- **Key Interactions:**
    - **Playback & Scrolling:** A white, vertical playhead is fixed at the horizontal center of the editor, overlaying the entire timeline editor. During playback, both the Time Ruler and the Video Tracks scroll in sync from right to left under the playhead. The scroll position is programmatically driven by the current playback time. The total scrollable width is proportional to the `totalDuration` from the `VideoViewModel`.
    - **Manual Scrubbing:** Users can manually drag the timeline (both ruler and tracks) horizontally to scrub through the video. This action updates the playback time for the entire composition.
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