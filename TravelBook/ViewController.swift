//
//  ViewController.swift
//  TravelBook
//
//  Created by Hamit  Tırpan on 27.09.2019.
//  Copyright © 2019 Hamit  Tırpan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager() // Konum alma vb. işlemler için kullanırım.
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        // Kullanıcının konumunu ne kadarlık bir keskinlikte olacağına karar veriyorum.Burada bir çok seçenek var.Eğer,Best ile çalışırsam en mükemmel keskinliği alır. Fakat Telefon pilini fazla harcar.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() // Kullanıcıdan location için izin istiyorum.Uygulamamı kullanırken !
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        gestureRecognizer.minimumPressDuration = 3 // Kaç saniye basılı tutunca algılanacak
        
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saved))
    }
    
    @objc func saved(){
    
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        if nameText.text == nil{
            let alertController = UIAlertController(title: "Attention", message: "Name cannot be empty.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else if commentText.text == nil{
            let alertController = UIAlertController(title: "Attention", message: "Comment cannot be empty.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        if nameText.text != nil && commentText.text != nil{
            
            newPlace.setValue(nameText.text, forKey: "title")
            newPlace.setValue(commentText.text, forKey: "subtitle")
            newPlace.setValue(chosenLatitude, forKey: "latitude")
            newPlace.setValue(chosenLongitude, forKey: "longitude")
            newPlace.setValue(UUID(), forKey: "id")
            
            do{
                try context.save()
                let alertController = UIAlertController(title: "SUCCESS", message: "place saved.", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }catch{
                let alertController = UIAlertController(title: "ERROR", message: "Something went wrong!", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
        // Dokunma başladığında
        if gestureRecognizer.state == .began{
            // Kullanıcının mapView üzerinde istediği yere dokunabilmesi
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            // Dokunularak belirlenen yeri koordianta çeviriyorum
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            //Pin oluşturma
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Kullanıcının kendi konumunu alıyorum.
        let location = CLLocationCoordinate2D.init(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        // Zoom yapmak için kullanıyorum.Oranlar ne kadar düşük ise zoom oranı o kadar yüksek.
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        // Region oluşturuyorum.Bu region belirlediğim konumu ve zoom in oranını alacak
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
}

