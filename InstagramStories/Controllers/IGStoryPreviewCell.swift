//
//  IGStoryPreviewCell.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 Dash. All rights reserved.
//

import UIKit

protocol StoryPreviewProtocol:class {
    func didCompletePreview()
    func didTapCloseButton()
}

final class IGStoryPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak private var scrollview: UIScrollView!{
        didSet{
            if let count = story?.snaps?.count {
                scrollview.contentSize = CGSize(width:IGScreen.width * CGFloat(count), height:IGScreen.height)
            }
        }
    }
    private lazy var storyHeaderView: IGStoryPreviewHeaderView = {
        let v = Bundle.loadView(with: IGStoryPreviewHeaderView.self)
        v.frame = CGRect(x:0,y:0,width:frame.width,height:80)
        return v
    }()
    private lazy var longPress_gesture: UILongPressGestureRecognizer = {
        let lp = UILongPressGestureRecognizer.init(target: self, action: #selector(didLongPress(_:)))
        lp.minimumPressDuration = 0.2
        return lp
    }()
    
    //MARK: - Overriden functions
    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(storyHeaderView)
        addGestureRecognizer(longPress_gesture)
    }
    
    //MARK: - iVars
    public weak var delegate:StoryPreviewProtocol? {
        didSet { storyHeaderView.delegate = self }
    }
    public var snapIndex:Int = 0 {
        didSet {
            if snapIndex < story?.snapsCount ?? 0 {
                if let snap = story?.snaps?[snapIndex] {
                    if let picture = snap.url {
                        createImageView(with:picture)
                    }
                    storyHeaderView.lastUpdatedLabel.text = snap.lastUpdated
                }
            }
        }
    }
    public var story:IGStory? {
        didSet {
            storyHeaderView.story = story
            if let picture = story?.user?.picture {
                storyHeaderView.snaperImageView.setImage(url: picture)
            }
        }
    }
    
    //MARK: - Private functions
    private func createImageView(with picture:String) {
        let iv = UIImageView(frame:
            CGRect(x:scrollview.subviews.last?.frame.maxX ?? CGFloat(0.0),y:0, width:IGScreen.width, height:IGScreen.height))
        startLoadContent(with: iv, picture: picture)
        scrollview.addSubview(iv)
    }
    
    private func startLoadContent(with imageView:UIImageView,picture:String) {
        imageView.setImage(url: picture, style: .squared, completion: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }else {
                let holderView = self.getProgressIndicatorView(with: self.snapIndex)
                let animatableView = self.getProgressView(with: self.snapIndex)
                animatableView.start(with: 1.0, width: holderView.frame.width, completion: {
                    self.didCompleteProgress()
                })
            }
        })
    }
    
    private func didCompleteProgress() {
        let n = snapIndex + 1
        if let count = story?.snapsCount {
            if n < count {
                //Move to next snap
                let x = n.toFloat() * frame.width
                let offset = CGPoint(x:x,y:0)
                scrollview.setContentOffset(offset, animated: false)
                snapIndex = n
            }else {
                delegate?.didCompletePreview()
            }
        }
    }
    
    private func getProgressView(with index:Int)->IGSnapProgressView {
        return storyHeaderView.subviews.first?.subviews.filter({v in v.tag == index+progressViewTag}).first as! IGSnapProgressView
    }
    
    private func getProgressIndicatorView(with index:Int)->UIView {
        return (storyHeaderView.subviews.first?.subviews.filter({v in v.tag == index+progressIndicatorViewTag}).first)!
    }
    
    public func willDisplayCell() {
        storyHeaderView.generateSnappers()
        snapIndex = 0
    }
    public func didEndDisplayingCell() {
        getProgressView(with: snapIndex).stop()
    }
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began || sender.state == .ended {
            let v = getProgressView(with: snapIndex)
            if sender.state == .began {
                v.pause()
            }else {
                v.play()
            }
        }
    }
}

extension IGStoryPreviewCell:StoryPreviewHeaderProtocol {
    func didTapCloseButton() {
        delegate?.didTapCloseButton()
    }
}
