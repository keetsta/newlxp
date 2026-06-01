import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house") }
            ScheduleView()
                .tabItem { Label("Расписание", systemImage: "calendar") }
            ServicesView()
                .tabItem { Label("Сервисы", systemImage: "square.grid.2x2") }
        }
    }
}

#Preview {
    ContentView()
}
