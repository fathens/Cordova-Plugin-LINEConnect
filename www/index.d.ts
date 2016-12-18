interface LINEConnectPlugin {
    login(arg?: string): Promise<string>;
    logout(): Promise<void>;
    getName(): Promise<string>;
    getId(): Promise<string>;
}
