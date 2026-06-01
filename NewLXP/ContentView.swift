import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Главная", systemImage: "house") {
                HomeView()
            }
            Tab("Расписание", systemImage: "calendar") {
                ScheduleView()
            }
            Tab("Сервисы", systemImage: "square.grid.2x2") {
                ServicesView()
            }
        }
    }
}

#Preview {
    ContentView()
}
