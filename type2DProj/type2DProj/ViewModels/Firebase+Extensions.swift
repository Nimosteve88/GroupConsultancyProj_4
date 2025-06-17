//
//  Firebase+Extensions.swift
//  type2DProj
//
//  Created by Nimo, Steve on 16/06/2025.
//

import FirebaseFirestore

extension DocumentReference {
    func getDocumentSync() throws -> DocumentSnapshot {
        let semaphore = DispatchSemaphore(value: 0)
        var document: DocumentSnapshot?
        var docError: Error?
        
        self.getDocument { snap, error in
            document = snap
            docError = error
            semaphore.signal()
        }
        
        semaphore.wait()
        if let error = docError { throw error }
        guard let doc = document else {
            throw NSError(domain: "getDocumentSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }
        return doc
    }
}
