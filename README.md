# Route Finder

Route Finder is an innovative route creation application designed to generate personalized itineraries based on user input. By leveraging advanced keyword matching, the application intelligently identifies and suggests relevant locations (e.g., inputting "hunger" suggests nearby restaurants) to construct a tailored route that meets the user's specific needs.

## AI Principles

This project integrates three core Artificial Intelligence principles to deliver a sophisticated and seamless user experience:

1.  **Natural Language Processing (NLP)**:
    We utilize NLP to intelligently map user input to specific place types compatible with the Google Places Nearby Search API. A lightweight Sentence Embedding Model processes user keywords to ensure accurate matching with existing place categories, guaranteeing that suggested locations align precisely with user intent.

2.  **Path Finding**:
    To ensure optimal navigation, we employ advanced path-finding algorithms. Once a route is generated, Dijkstra's algorithm is utilized to calculate the most efficient on-foot path connecting all selected points of interest, maximizing convenience and time efficiency.

3.  **Sentiment Analysis**:
    We prioritize quality by incorporating a Sentence Sentiment Analysis Model. This model evaluates user reviews and feedback for potential locations, ensuring that only places with positive sentiment and high standards are suggested in the final route.

> **Microservices Architecture**: To ensure optimal performance and minimize local resource usage on the user's device, these computationally intensive AI processes are not executed locally. Instead, they are offloaded to Python-based microservices hosted on **Google Cloud Run**. This architecture allows us to leverage the flexibility of Python for AI tasks while maintaining a lightweight and responsive mobile application.

## Installation Guide

Follow these steps to set up and run the Route Finder application locally.

### Prerequisites

-   **Dart & Flutter**: Ensure that the Dart SDK and Flutter framework are installed on your development machine.
    -   For installation instructions, please refer to the official guide: [Install Flutter](https://docs.flutter.dev/get-started/install)

### Steps

1.  **Clone the Repository**
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2.  **Install Dependencies**
    Flutter will automatically resolve and fetch necessary dependencies upon running the project. Alternatively, you can install them manually:
    ```bash
    flutter pub get
    ```

3.  **Run the Application**
    For the best performance and stability, launch the application in release mode:

    **For macOS Users:**
    Open the Simulator and run:
    ```bash
    flutter run --release
    ```

    **For Windows Users:**
    Open Android Studio, start a virtual device (AVD), and run:
    ```bash
    flutter run --release
    ```
    
    > **Note:** You can also run the application in a personal device, but you will need to enable USB debugging and connect your device to your computer.