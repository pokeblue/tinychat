//
//  SimpleSocket.swift
//  tinychat
//
//  Created by yongkeun oh on 2017-12-12.
//  Copyright © 2017 opengarden. All rights reserved.
//

import Foundation

protocol SimpleSocketDelegate: class {
    func receivedMessage(message: Message)
}

struct Message: Codable {
    var msg : String?
    var command: String?
    var since: Double?
    var client_time : Double
    var server_time : Double?
}

class SimpleSocket: NSObject {
    weak var delegate: SimpleSocketDelegate?
    var inputstream: InputStream?
    var outputstream: OutputStream?
    let host = "52.91.109.76"
    let port = 1234
    let maxReadLength = 4096

    override init() {
        super.init()
        
        Stream.getStreamsToHost(
            withName: host,
            port: port,
            inputStream: &inputstream,
            outputStream: &outputstream
        )
        
        inputstream?.delegate = self
        outputstream?.delegate = self
        
        inputstream?.schedule(in: .current, forMode: .defaultRunLoopMode)
        outputstream?.schedule(in: .current, forMode: .defaultRunLoopMode)
    }
    
    deinit {

    }
    
    func open() {
        if let inputstream = inputstream {
            if inputstream.streamStatus != .open {
                inputstream.open()
            }
        }
        if let outputstream = outputstream {
            if outputstream.streamStatus != .open {
                outputstream.open()
            }
        }
    }
    
    func close() {
        inputstream?.close()
        outputstream?.close()
    }
    
    func terminate() {
        close()
        inputstream?.remove(from: .current, forMode: .defaultRunLoopMode)
        outputstream?.remove(from: .current, forMode: .defaultRunLoopMode)
        inputstream = nil
        outputstream = nil
    }
    
    func sendMessage(message: Message) -> Bool {
        guard let outputstream = outputstream else {
            return false
        }
        
        if outputstream.streamStatus != .open {
            outputstream.open()
            print("opening...")
        }
        
        DispatchQueue.global(qos: .background).async {
            let jsonEncoder = JSONEncoder()
            do {
                var jsonData = try jsonEncoder.encode(message)
                // "\n" is required at end of data.
                if let extraData = "\n".data(using: .utf8) {
                    jsonData.append(extraData)
                }
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("JSON String : " + jsonString)
                }
                
                let bytesWritten = jsonData.withUnsafeBytes { outputstream.write($0, maxLength: jsonData.count) }
                
                if bytesWritten < 0, let error = outputstream.streamError {
                    print("Input stream has less than 0 bytes\(error)")
                } else {
                    print("\(bytesWritten) bytes written to stream")
                }
            } catch {
                
            }
        }

        return true
    }
}

// MARK: StreamDelegate

extension SimpleSocket: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch (eventCode) {
        case Stream.Event.openCompleted:
            print("openCompleted")
        case Stream.Event.errorOccurred:
            print("Error Occurred\n")
        case Stream.Event.endEncountered:
            print("endEncountered\n")
        case Stream.Event.hasSpaceAvailable:
            print("hasSpaceAvailable\n")
        case Stream.Event.hasBytesAvailable:
            if(aStream == inputstream) {
                parseBytesAvailable(stream: aStream)
            }
        default:
            print("default block")
        }
    }
    
    private func parseBytesAvailable(stream: Stream) {
        guard let stream = stream as? InputStream else {
            return
        }
        
        var streamData = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        
        while (stream.hasBytesAvailable) {
            let len = stream.read(buffer, maxLength: maxReadLength)
            
            if len < 0 {
                if let error = stream.streamError {
                    print("Input stream has less than 0 bytes\(error)")
                }
            } else if len == 0 {
                print("Input stream has 0 bytes")
                break
            } else {
                streamData.append(buffer, count: len)
            }
        }
        
        buffer.deallocate(capacity: maxReadLength)
        
        let decoder = JSONDecoder()
        do {
            let message = try decoder.decode(Message.self, from: streamData)
            delegate?.receivedMessage(message: message)
        } catch {
            _ = String(data: streamData, encoding: .utf8)
            
            print("Error info: \(error)")
        }
    }
}
