//
//  MapView.swift
//  GameMap
//
//  Created by Melody Lee on 4/22/18.
//  Copyright © 2018 Hackathon Event. All rights reserved.
//

import UIKit

class MapView: UIViewController {
    @IBOutlet weak var imageView:UIImageView!
    var num:Int=6
    func updateImage() -> Void {
            let image=UIImage(named: redDot)
            let imageView=UIImageView(image:image!);
            imageView.frame=CGRect(x:0,y:0,width:100,height:200)
            view.addSubview(imageView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateImage()
        //updateImage()
        
    }
    
}
