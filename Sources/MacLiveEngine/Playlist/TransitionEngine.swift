import AppKit
import QuartzCore

/// Animates transitions between wallpaper views.
final class TransitionEngine {
    
    func transition(from oldView: NSView?, to newView: NSView, in container: NSView,
                    style: TransitionStyle, duration: TimeInterval, completion: (() -> Void)? = nil) {
        
        guard style != .none else {
            oldView?.removeFromSuperview()
            container.addSubview(newView)
            completion?()
            return
        }
        
        newView.frame = container.bounds
        newView.autoresizingMask = [.width, .height]
        
        switch style {
        case .crossfade:
            newView.alphaValue = 0
            container.addSubview(newView)
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = duration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                newView.animator().alphaValue = 1
                oldView?.animator().alphaValue = 0
            }, completionHandler: {
                oldView?.removeFromSuperview()
                completion?()
            })
            
        case .dissolve:
            let transition = CATransition()
            transition.type = .fade
            transition.duration = duration
            container.layer?.add(transition, forKey: "transition")
            oldView?.removeFromSuperview()
            container.addSubview(newView)
            completion?()
            
        case .slideLeft:
            performSlide(from: oldView, to: newView, in: container,
                         offset: CGPoint(x: -container.bounds.width, y: 0),
                         duration: duration, completion: completion)
            
        case .slideRight:
            performSlide(from: oldView, to: newView, in: container,
                         offset: CGPoint(x: container.bounds.width, y: 0),
                         duration: duration, completion: completion)
            
        case .zoomIn:
            newView.layer?.transform = CATransform3DMakeScale(0.5, 0.5, 1)
            newView.alphaValue = 0
            container.addSubview(newView)
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = duration
                newView.animator().alphaValue = 1
                newView.layer?.transform = CATransform3DIdentity
                oldView?.animator().alphaValue = 0
            }, completionHandler: {
                oldView?.removeFromSuperview()
                completion?()
            })
            
        case .zoomOut:
            container.addSubview(newView, positioned: .below, relativeTo: oldView)
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = duration
                oldView?.animator().alphaValue = 0
                oldView?.layer?.transform = CATransform3DMakeScale(1.5, 1.5, 1)
            }, completionHandler: {
                oldView?.removeFromSuperview()
                completion?()
            })
            
        case .none:
            break
        }
    }
    
    private func performSlide(from oldView: NSView?, to newView: NSView, in container: NSView,
                               offset: CGPoint, duration: TimeInterval, completion: (() -> Void)?) {
        var startFrame = container.bounds
        startFrame.origin.x -= offset.x
        startFrame.origin.y -= offset.y
        newView.frame = startFrame
        container.addSubview(newView)
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            newView.animator().frame = container.bounds
            if let old = oldView {
                var endFrame = old.frame
                endFrame.origin.x += offset.x
                endFrame.origin.y += offset.y
                old.animator().frame = endFrame
            }
        }, completionHandler: {
            oldView?.removeFromSuperview()
            completion?()
        })
    }
}
