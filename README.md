## 1. Visemble 프로젝트 소개
Visemble은 **세 컷 그리드 영상**을 쉽게 만들 수 있는 영상 편집 서비스입니다.

기존 영상 편집 서비스의 조작을 복잡하게 느끼는 사용자가  
영상을 선택하고 길이만 조정해서 세 컷 영상을 만들 수 있습니다.

## 2. 개발 환경

| Technology | Description |
|------------|-------------|
| **SwiftUI + UIKit (Hybrid)** | UI와 상태 관리는 SwiftUI로 처리하고, 영상 길이 조절 트랙 등 세밀한 제어가 필요한 컴포넌트는 UIKit로 구현 |
| **AVFoundation** | 영상 편집과 출력이 필요한 앱 특성상, 비디오 구성·변형·내보내기까지 직접 제어하기 위해 사용 |
| **Photos** | 사용자의 비디오 에셋을 안전하게 불러오고, 선택 상태 및 썸네일을 효율적으로 관리하기 위해 사용 |
| **AVKit** | 시스템 플레이어 기능을 활용한 안정적인 미디어 재생 |
| **MVVM + Clean Architecture** | UI와 비즈니스 로직을 분리하고, 영상 편집 로직을 UseCase 단위로 구성하여 유지보수성과 확장성을 고려 |
| **Swift Concurrency (async/await)** | 비동기 작업을 명확하고 안전하게 관리하여 미디어 로딩 및 처리 흐름을 단순화 |

## 3. 주요 기능
| 제작한 영상 갤러리 | 앨범에서 영상 선택 | 세 컷 영상에 표시할 영역 크롭 |
|---------|---------|-------------|
| ![Home](https://github.com/user-attachments/assets/71eed6cf-0119-46e9-8fec-e06860bdac0d)  | ![Picker](https://github.com/user-attachments/assets/d8baaf5d-023f-4d54-a700-4aad737bf55f) | ![Crop](https://github.com/user-attachments/assets/8aa3319b-650d-4d57-bad0-0dc410ed26f9) |
| 앱에서 만든 영상을 갤러리로 재생할 수 있는 뷰<br> | 앨범에서 영상 선택 | 세 컷 영상에 표시할 영역 크롭 |

| 영상 길이 트리밍 | 영상 스크러빙(시간 이동) | 트리밍한 영상 재생 및 전체화면 |
|---------|---------|-------------|
| ![Trim](https://github.com/user-attachments/assets/90a590b1-4d7c-45ec-a5ce-e18887e89b41) | ![Seek](https://github.com/user-attachments/assets/48231406-39c0-404b-b6be-28e3c0bf541f) | ![FullScreen](https://github.com/user-attachments/assets/f4d6ba07-1e61-41a6-b44d-abd057608fc5) |
