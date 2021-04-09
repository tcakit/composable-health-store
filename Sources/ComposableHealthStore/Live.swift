// Live.swift
// Copyright (c) 2021 Joe Blau

#if canImport(HealthKit)
    import Combine
    import ComposableArchitecture
    import Foundation
    import HealthKit

    public extension HealthStoreManager {
        static let live: HealthStoreManager = { () -> HealthStoreManager in

            var manager = HealthStoreManager()

            manager.connectionStatus = { id in
                return dependencies[id]?.connectionStatus ??  .unknown
            }
            
            manager.create = { id in
                Effect.run { subscriber in
                    
                    dependencies[id] = Dependencies(
                        connectionStatus: ConnectionStatus(rawValue: UserDefaults.standard.integer(forKey: "\(HealthStoreManager.self)_status_key")) ?? .unknown,
                        healthStore: HKHealthStore(),
                        subscriber: subscriber
                    )

                    return AnyCancellable {
                        dependencies[id] = nil
                    }
                }
            }

            manager.destroy = { id in
                .fireAndForget {
                    let statusKey = dependencies[id]?.connectionStatus ?? .unknown
                    UserDefaults.standard.set(statusKey.rawValue, forKey: "\(HealthStoreManager.self)_status_key")
                    dependencies[id]?.subscriber.send(completion: .finished)
                    dependencies[id] = nil
                }
            }

            manager.requestAuthorization = { id, typesToShare, typeToRead in
                .fireAndForget {
                    guard HKHealthStore.isHealthDataAvailable() else { return }
                    dependencies[id]?.healthStore.requestAuthorization(toShare: typesToShare, read: typeToRead) { _, _ in
                        dependencies[id]?.connectionStatus = .connected
                    }
                }
            }

            manager.isHealthAuthorizedFor = { id, typesToShare, typesToRead in
                .future { futureCompletion in
                    dependencies[id]?.healthStore.getRequestStatusForAuthorization(toShare: typesToShare, read: typesToRead, completion: { status, error in
                        switch error {
                        case .some:
                            break
                        case .none:
                            switch status {
                            case .unnecessary: return futureCompletion(.success(true))
                            default: return futureCompletion(.success(false))
                            }
                        }
                    })
                }
            }

            manager.startWatchApp = { id, configuration in
                .future { futureCompletion in
                    dependencies[id]?.healthStore.startWatchApp(with: configuration, completion: { _, error in
                        switch error {
                        case .some:
                            return futureCompletion(.success(false))
                        case .none:
                            return futureCompletion(.success(true))
                        }
                    })
                }
            }

            return manager
        }()
    }

    private struct Dependencies {
        var connectionStatus: ConnectionStatus
        var healthStore: HKHealthStore
        let subscriber: Effect<HealthStoreManager.Action, Never>.Subscriber
    }

    private var dependencies: [AnyHashable: Dependencies] = [:]
#endif
