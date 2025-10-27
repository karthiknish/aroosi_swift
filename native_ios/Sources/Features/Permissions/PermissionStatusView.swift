#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct PermissionStatusView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("App Permissions") {
                    ForEach(PermissionType.allCases, id: \.self) { permissionType in
                        PermissionRowView(
                            type: permissionType,
                            status: permissionManager.permissionStatuses[permissionType] ?? .notDetermined,
                            onTap: {
                                Task {
                                    await permissionManager.requestPermission(permissionType)
                                }
                            }
                        )
                    }
                }
                .listRowBackground(AroosiColors.groupedSecondaryBackground)
                
                Section("Permission Information") {
                    Button("Check All Permissions") {
                        Task {
                            await permissionManager.checkAllPermissions()
                        }
                    }
                    .foregroundStyle(AroosiColors.primary)
                    
                    Button("Reset Permission Cache") {
                        permissionManager.permissionStatuses.removeAll()
                    }
                    .foregroundStyle(AroosiColors.warning)
                }
                .listRowBackground(AroosiColors.groupedSecondaryBackground)
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await permissionManager.checkAllPermissions()
            }
            .overlay(alignment: .top) {
                if permissionManager.showingPermissionAlert {
                    PermissionAlertView(permissionManager: permissionManager)
                        .padding()
                        .transition(.move(edge: .top))
                        .zIndex(1000)
                }
            }
        }
        .tint(AroosiColors.primary)
    }
}

@available(iOS 17, *)
struct PermissionRowView: View {
    let type: PermissionType
    let status: PermissionStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundStyle(status.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(AroosiColors.text)
                    
                    Text(type.description)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: status.systemImage)
                            .font(.caption)
                        Text(status.description)
                            .font(AroosiTypography.caption(weight: .medium))
                    }
                    .foregroundStyle(status.color)
                    
                    if status == .notDetermined {
                        Text("Tap to request")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.primary)
                    } else if status == .denied || status == .restricted {
                        Text("Tap to fix")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.warning)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
#Preview {
    PermissionStatusView()
        .environmentObject(NavigationCoordinator())
}

#endif
