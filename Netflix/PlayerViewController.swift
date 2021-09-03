//
//  AppDelegate.swift
//  Netflix
//
//  Created by sunny h on 2021/09/03.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {


    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var contollerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    let player = AVPlayer()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = player
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        play()
    }
    
    @IBAction func togglePlayButton(_ sender: Any) {
        if player.isPlaying {
            pause()
        }else {
            play()
            
        }
    }
    

    
    
    func play(){
        player.play()
        playButton.isSelected = true

    }
    func pause(){
        player.pause()
        playButton.isSelected = false
    
        
    }
    
    func reset() {
        pause()
        player.replaceCurrentItem(with: nil)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        reset()
        dismiss(animated: false, completion: nil)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        guard self.currentItem != nil else { return false }
        return self.rate != 0
    }
}
    


    

