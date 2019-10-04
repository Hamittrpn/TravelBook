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
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotatitonLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        // Kullanıcının konumunu ne kadarlık bir keskinlikte olacağına karar veriyorum.Burada bir çok seçenek var.Eğer,Best ile çalışırsam en mükemmel keskinliği alır. Fakat Telefon pilini fazla harcar.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() // Kullanıcıdan location için izin istiyorum.Uygulamamı kullanırken !
        locationManager.startUpdatingLocation() // Kullanıcı lokasyonunu alıyorum.
        

        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        gestureRecognizer.minimumPressDuration = 3 // Kaç saniye basılı tutunca algılanacak
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            //Core Data İşlemleri
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            // Sadece id'si bu olan veriyi getir
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
               let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as!  [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotatitonLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2DMake(annotatitonLatitude, annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        // Aldığım location bana yeter artık almayı durdur.
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                let alertController = UIAlertController(title: "Attention", message: "Something went wrong", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            // Kullanıcının kendi konumunu alıyorum.
            let location = CLLocationCoordinate2D.init(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // Zoom yapmak için kullanıyorum.Oranlar ne kadar düşük ise zoom oranı o kadar yüksek.
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            // Region oluşturuyorum.Bu region belirlediğim konumu ve zoom in oranını alacak
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else{
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Navigation açmak için kullanıcının kendi konumundan işaretlediği konuma gideceğim için kullanıcının konumunda pin göstermek istemiyorum.Bu onun ayarı.
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // Ekstra bir baloncuk ile bilgi gösterimi
            pinView?.tintColor = UIColor.blue // Annotationlar kırmızı çıkıyordu.Rengi buradan değiştirebilirim.
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) // Detay göstermek için buton
            pinView?.rightCalloutAccessoryView = button // Pin'e tıkladığımda bilgi kartının sağ tarafına İnfo logosu şeklinde buton
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    // rightCalloutAccessoryView'a (İnfo Logosu) neler olacağını kontrol edeceğim.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            // Koordinatlar ve yerler arasında ilişki kurar.
            let requestLocation = CLLocation(latitude: annotatitonLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                // Bu yapıya Closure deniyor. Bir işlem sonucu bana ya bir error ya da bir dizi(sonuç) dönüyor.
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        
                        //MapItem oluşturabilmek için MKPlacemark'tan obje oluşturmam gerekiyor.Bu objeyide Yukarıda Geocoder metodundan alıyoruz.
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark) // Navigasyonu açabilmem için MKMapItem gerekli
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
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
                
                print("Place Saved")
                NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
                navigationController?.popViewController(animated: true) // Bir önceki sayfaya dönmek için

                // Kaydetme işleminden sonra
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
    
}

