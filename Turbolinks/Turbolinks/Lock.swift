import Foundation

class Lock {
    var locked: Bool = true
    var queue: dispatch_queue_t
    
    init(queue: dispatch_queue_t) {
        self.queue = queue
    }
    
    func afterUnlock(completion: () -> ()) {
        if locked {
            dispatch_group_notify(dispatchGroup, queue, completion)
        } else {
            dispatch_async(queue, completion)
        }
    }
    
    func unlock() {
        if locked {
            self.locked = false
            dispatch_group_leave(dispatchGroup)
        }
    }
    
    lazy private var dispatchGroup: dispatch_group_t = {
        let dispatchGroup = dispatch_group_create()
        dispatch_group_enter(dispatchGroup)
        return dispatchGroup
    }()
}

