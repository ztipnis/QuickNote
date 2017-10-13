//
//  QNConnection.swift
//  Quicknote-Connect
//
//  Created by Zachary A. Tipnis on 3/10/17.
//
//

import MultipeerConnectivity

public class QNConnection: NSObject {
    
    public var peerID:MCPeerID?
    public var session:MCSession?
    public var browser:MCBrowserViewController?
    public var advertiser:MCAdvertiserAssistant?
    
    public func setupPeerIDAndSession(with displayName:String){
        peerID = MCPeerID.init(displayName: displayName)
        session = MCSession.init(peer: peerID!)
        session?.delegate = self
    }
    
    public func setupMCBrowser() {
        
        browser = MCBrowserViewController.init(serviceType: "photoSender", session: session!)
    }
    
    public func advertiseSelf(shouldAdvertise:Bool){
        if shouldAdvertise{
            advertiser = MCAdvertiserAssistant.init(serviceType: "photoSender", discoveryInfo: nil, session: session!)
            advertiser?.start()
        }else{
            advertiser?.stop()
            advertiser = nil
        }
    }
}

extension QNConnection:MCSessionDelegate {
   
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
}
