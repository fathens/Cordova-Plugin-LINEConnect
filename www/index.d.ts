interface LINEConnectPlugin {
    connect(): Promise<string>;
    disconnect(): Promise<void>;
}
