import Foundation
import Cordova

func log(_ msg: String) {
    print(msg)
}

@objc(LINEConnect)
class LINEConnect: CDVPlugin {
    lazy private var adapter: LineAdapter = LineAdapter.default()
    private var currentCommand: CDVInvokedUrlCommand?
    
    // MARK: - Plugin Commands

    func login(_ command: CDVInvokedUrlCommand) {
        fork(command) {
            if self.adapter.isAuthorized {
                self.finish_error("Already authorized.")
            } else {
                if self.adapter.canAuthorizeUsingLineApp {
                    self.adapter.authorize()
                } else {
                    self.finish_error("LINE is not installed.")
                }
            }
            
        }
    }
    
    func logout(_ command: CDVInvokedUrlCommand) {
        fork(command) {
            log("Logout now!")
            self.adapter.unauthorize()
        }
    }
    
    func getName(_ command: CDVInvokedUrlCommand) {
        fork(command) {
            self.getProfile("displayName")
        }
    }
    
    func getId(_ command: CDVInvokedUrlCommand) {
        fork(command) {
            self.getProfile("mid")
        }
    }
    
    private func getProfile(_ key: String) {
        if self.adapter.isAuthorized {
            self.adapter.getLineApiClient().getMyProfile { (profile, error) -> Void in
                if let error = error {
                    self.finish_error(error.localizedDescription)
                } else {
                    if let p = profile, let value = p[key] as? String {
                        self.finish_ok(value)
                    } else {
                        self.finish_error("Empty profile")
                    }
                }
            }
        } else {
            self.finish_error("Not login")
        }
    }
    
    // MARK: - Override Methods

    override func handleOpenURL(_ notification: Notification) {
        let url = notification.object! as! URL
        LineAdapter.handleOpen(url)
    }

    override func pluginInitialize() {
        func observe(_ name: NSNotification.Name, _ selector: Selector) {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
        observe(.UIApplicationDidFinishLaunching, #selector(LINEConnect.finishLaunching(_:)))
        observe(.LineAdapterAuthorizationDidChange, #selector(LINEConnect.authorizationDidChange(_:)))
    }
    
    // MARK: - Event Listeners
    
    func cancel(_ sender: AnyObject) {
        finish_error("Canceled.")
    }

    func finishLaunching(_ notification: Notification) {
        let options = (notification as NSNotification).userInfo != nil ? (notification as NSNotification).userInfo : [:]
        LineAdapter.handleLaunchOptions(options)
    }
    
    func authorizationDidChange(_ notification: Notification) {
        let adapter = notification.object as! LineAdapter
        
        if let command = currentCommand {
            if let error = notification.userInfo?["error"] as? NSError {
                finish_error(error.localizedDescription)
            } else {
                switch command.methodName {
                case "logout" where !adapter.isAuthorized:
                    finish_ok()
                case "login" where adapter.isAuthorized:
                    getProfile("mid")
                default:
                    finish_error("Login status: \(adapter.isAuthorized)")
                }
            }
        }
    }
    
    // MARK: - Private Utillities
    
    private func fork(_ command: CDVInvokedUrlCommand, _ proc: @escaping () -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async(execute: {
            self.currentCommand = command
            defer {
                self.currentCommand = nil
            }
            proc()
        })
    }

    private func finish_error(_ msg: String!) {
        if let command = self.currentCommand {
            commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
        }
    }
    
    private func finish_ok(_ result: Any? = nil) {
        if let command = self.currentCommand {
            log("Command Result: \(result)")
            if let msg = result as? String {
                commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg), callbackId: command.callbackId)
            } else if let dict = result as? [String: AnyObject] {
                commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dict), callbackId: command.callbackId)
            } else if result == nil {
                commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
            }
        }
    }
}
