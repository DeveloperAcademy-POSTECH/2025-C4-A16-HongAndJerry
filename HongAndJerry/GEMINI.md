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
│   ├───Info.plist
│   ├───Assets.xcassets/
│   ├───Preview Content/
│   ├───Resources/
│   │   ├───video1.MP4
│   │   ├───video2.MOV
│   │   └───video3.MOV
│   └───Source/
│       ├───App/
│       │   └───HongAndJerryApp.swift
│       ├───DesignSystem/
│       │   ├───ButtonType.swift
│       │   ├───CtaButton.swift
│       │   ├───Font.swift
│       │   ├───Spacing.swift
│       │   └───Font/
│       ├───Extension/
│       │   ├───CMTime++.swift
│       │   ├───VideoSegment++.swift
│       │   └───VideoSource++.swift
│       ├───Model/
│       │   ├───CompositionBuildResult.swift
│       │   ├───VideoSegment.swift
│       │   └───VideoSource.swift
│       ├───Presentation/
│       │   ├───Crop/
│       │   ├───Export/
│       │   ├───Home/
│       │   ├───Picker/
│       │   └───VideoEditor/
│       ├───Service/
│       │   ├───CompositionBuilder.swift
│       │   ├───PlayerController.swift
│       │   └───EditOperations/
│       ├───Type/
│       ├───Utils/
│       └───ViewModel/
│           └───VideoViewModel.swift
└───HongAndJerry.xcodeproj/
```

## 6. Communication Rules
- To save tokens, please answer in English.

## 7. Trim Feature Implementation Plan

**Core Principle:** The UI representation is a clipped "viewport" into the full data model. The data model stores absolute time, while the view calculates its appearance based on that data.

**1. Data Model (`VideoSegment.swift`):**
   - Must store `trimStartTime` and `trimEndTime` as **absolute time values** relative to the original video source.
   - This data is the single source of truth.

**2. View Logic (`VideoTrackView.swift`) - The "Viewport" Model:**
   - **Visual Start:** The view for each track must always visually start at the 0s mark of the timeline.
   - **Hidden Content:** Trimmed-out portions of the video are not grayed out; they are completely hidden.
   - **Implementation Steps:**
     a. **Inner Container:** The view contains an inner `HStack` that holds the thumbnails for the **entire duration of the original video**.
     b. **Offset Calculation:** This inner `HStack` is given a horizontal offset calculated as `offsetX = -trimStartTime.seconds * pixelsPerSecond`. This shifts the full thumbnail strip to the left, aligning the desired start frame with the view's leading edge (the 0s position).
     c. **Frame & Clipping:** The parent `VideoTrackView` sets its own frame width based on the **trimmed duration**: `width = (trimEndTime - trimStartTime).seconds * pixelsPerSecond`. It then applies `.clipped()` to hide any part of the inner `HStack` that falls outside this frame.

**3. Interaction Logic (`DragGesture` on Trim Handles):**
   - Dragging a handle modifies the `trimStartTime` or `trimEndTime` values in the data model.
   - This data change automatically triggers two updates:
     a. **UI Update:** The `VideoTrackView`'s offset and frame width are recalculated, creating the illusion that hidden thumbnails are being revealed as the frame expands.
     b. **Player Update:** The `VideoViewModel` rebuilds the `AVComposition` using the new time range and updates the `AVPlayer` item.

---
## 8. System Architecture Blueprint

### 8.1. Guiding Principles

*   **Single Source of Truth**: The `VideoViewModel`'s `segments` array is the ultimate authority on the project's state. All other components must derive their state from this source.
*   **Command Pattern**: All state modifications MUST be encapsulated in `EditOperation` objects. This ensures operations are testable, extensible, and potentially reversible (Undo/Redo).
*   **Strict Separation of Concerns**: Each component adheres to a single, well-defined responsibility, modeled after a film production team.
    *   `VideoViewModel`: Orchestration (The Producer).
    *   `PlayerController`: Playback Control (The Operator).
    *   `CompositionBuilder`: `AVFoundation` Logic (The Editor).
*   **Stateful vs. Stateless Implementation**:
    *   **`class`**: Used for objects with a unique identity and shared, mutable state (e.g., `VideoSegment`, `PlayerController`, `VideoViewModel`).
    *   **`struct`**: Used for stateless "worker" objects that perform calculations without maintaining state (e.g., `CompositionBuilder`, `TrimOperation`).

### 8.2. Component Roles & Responsibilities

#### a. `VideoSegment` (class)
- **Persona**: Raw Footage Can.
- **Primary Responsibility**: To be the data model for a single video clip, holding all its associated state.
- **Implementation Rationale**: MUST be a `class` (reference type) because it represents a unique entity with an identity that is shared and mutated across the app. It works with the `@Observable` framework.
- **Core State & Data**: `asset`, `trimStartTime`, `trimEndTime`, `thumbnails`.
- **Core Behaviors & API**: `generateThumbnails()`.

#### b. `CompositionBuilder` (struct)
- **Persona**: The Film Editor.
- **Primary Responsibility**: To translate the `[VideoSegment]` array into a playable `AVPlayerItem` by handling all complex `AVFoundation` logic.
- **Implementation Rationale**: MUST be a `struct` (value type) because it is a stateless worker. It takes input, produces output, and retains no memory of past operations, ensuring thread safety and predictability.
- **Core Behaviors & API**: `build(from: [VideoSegment]) -> CompositionBuildResult`.

#### c. `PlayerController` (class)
- **Persona**: The Playback Operator.
- **Primary Responsibility**: To own, manage, and control the `AVPlayer` instance.
- **Implementation Rationale**: MUST be a `class` because it manages a unique, stateful system resource (`AVPlayer`).
- **Core State & Data**: `player`, `isPlaying`, `currentTime`.
- **Core Behaviors & API**: `play()`, `pause()`, `seek(to:)`, `replaceCurrentItem(with:)`.

#### d. `EditOperation` (protocol)
- **Persona**: The Work Order.
- **Primary Responsibility**: To define a contract that encapsulates a single, atomic editing action.
- **Implementation Rationale**: A `protocol` is used to define a common interface for all command objects, enabling the Command Pattern.
- **Core Behaviors & API**: `apply(on: [VideoSegment]) -> EditResult`.

#### e. `VideoViewModel` (class)
- **Persona**: The Executive Producer.
- **Primary Responsibility**: To act as the central coordinator, orchestrating all interactions between the UI and the system's specialist components. It owns the application's high-level state.
- **Implementation Rationale**: MUST be a `class` as it owns the application's core state (`segments`) and must persist throughout the app's lifecycle.
- **Core State & Data**: `segments` (Source of Truth), `playerController` (dependency), `isScrubbing`.
- **Core Behaviors & API**:
    - `perform(operation: EditOperation)`: The single, unified entry point for all state-mutating requests from the UI.
    - `rebuildPlayerItem()`: A private method to coordinate the `CompositionBuilder` and `PlayerController` after a state change.
