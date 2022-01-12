//
//  ViewController.swift
//  testNasaApp
//
//  Created by Sai Leung on 1/11/22.
//

import UIKit
import WebKit
import CoreData

class ViewController: UIViewController {
    @IBOutlet weak var todayApodTitle: UILabel!
    @IBOutlet weak var apodDate: UILabel!
    @IBOutlet weak var apodTitle: UILabel!
    @IBOutlet weak var apodImage: UIImageView!
    @IBOutlet weak var apodExplanation: UITextView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var webView: WKWebView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    private var apiKey: String {
        return Bundle.main.infoDictionary?["API_KEY"]  as? String ?? ""
    }
    private let timeHelper = TimeHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialUISetup()
        fetchTodayApodData()
    }
    
    @IBAction func datePickerSelected(_ sender: Any) {
        datePicker.setDate(datePicker.date, animated: true)
        if datePicker.date > Date() {
            presentedViewController?.dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Date not available", message: "Please select another date!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            getAPOD(date: datePicker.date)
        }
    }
}

// MARK: - UI Handling
extension ViewController {
    
    func initialUISetup() {
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        if let nasaImage = UIImage(named: "nasa.png") {
            let backgroundImage = UIImageView(frame: containerView.frame)
            backgroundImage.image = nasaImage
            backgroundImage.contentMode = .scaleAspectFit
            containerView.insertSubview(backgroundImage, at: 0)
            backgroundImage.frame.size.height = 120
        }
        
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: containerView.frame.size.width, height: containerView.frame.size.height))
    }
    
    func clearPreviousLoadedImageAndData() {
        webView.removeFromSuperview()
        apodImage.image = nil
        apodDate.text = ""
        apodTitle.text = ""
        apodExplanation.text = ""
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func loadApodImage(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.apodImage.image = image
                        self?.cachingApodImage(data: data)
                    }
                }
            }
        }
    }
}

// MARK: - Network Handling
extension ViewController {
    
    func createURLWithComponents(date: Date) -> URL? {
        // create "https://api.nasa.gov/planetary/apod" URL using URLComponents
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.nasa.gov"
        urlComponents.path = "/planetary/apod"
        
        // add params based on date selected
        let dateQuery = URLQueryItem(name: "date", value: timeHelper.dateToString(date: date))
        let apiKeyQuery = URLQueryItem(name: "api_key", value: apiKey)
        urlComponents.queryItems = [dateQuery, apiKeyQuery]
        
        return urlComponents.url as URL?
    }
    
    func fetchTodayApodData() {
        /* Before fetching daily APOD, need to deter and make sure user's local timezone is not a day ahead of US timezone, otherwise we need to fetch data based on the latest avaiable date according to US time */
        if timeHelper.checkUserLocalTimeIsAheadOfNasaPostingTime() {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
                return
            }
            getAPOD(date: yesterday)
        } else {
            let today = Date()
            getAPOD(date: today)
        }
    }
    
    func getAPOD(date: Date) {
        clearPreviousLoadedImageAndData()
        guard let url = createURLWithComponents(date: date) else {
            print("invalid URL")
            return
        }
        let urlRequest = NSURLRequest(url: url as URL)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { [weak self] (data, reponse, error) in
            guard error == nil else {
                self?.loadCachedApodData()
                return
            }
            if let data = data {
                do {
                    let apod = try JSONDecoder().decode(Apod.self, from: data)
                    DispatchQueue.main.async {
                        if apod.date != self?.timeHelper.dateToString(date: Date()) {
                            self?.todayApodTitle.text = "APOD"
                        } else {
                            self?.todayApodTitle.text = "Today's APOD"
                        }
                        self?.apodDate.text = self?.timeHelper.stringToDateString(string: apod.date)
                        self?.apodTitle.text = apod.title
                        self?.apodExplanation.text = apod.explanation
                        self?.cachingLastApodCallData(apod: apod)
                        if let imageUrl = URL(string: apod.url) {
                            if apod.mediaType == .image {
                                self?.apodImage.isHidden = false
                                self?.loadApodImage(url: imageUrl)
                            } else {
                                if let webView = self?.webView {
                                    self?.apodImage.isHidden = true
                                    self?.containerView.addSubview(webView)
                                    webView.load(URLRequest(url: imageUrl))
                                }
                            }
                        }
                    }
                } catch {
                    self?.loadCachedApodData()
                    print(error)
                }
            } else {
                self?.loadCachedApodData()
            }
        })
        task.resume()
    }
}

// MARK: - CoreData Caching
extension ViewController {
    
    func cachingLastApodCallData(apod: Apod) {
        appDelegate.deleteAllEntities()
        
        let cachedAPOD = CachedAPOD(context: context)
        cachedAPOD.setValue(timeHelper.stringToDateString(string: apod.date), forKey: "apodDate")
        cachedAPOD.setValue(apod.explanation, forKey: "apodExplanation")
        cachedAPOD.setValue(apod.title, forKey: "apodTitle")
        cachedAPOD.setValue(apod.mediaType == .image, forKey: "isImage")
        if let imageUrl = URL(string: apod.url) {
            cachedAPOD.setValue(imageUrl, forKey: "apodUrl")
        }
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func cachingApodImage(data: Data) {
        let fetchRequest: NSFetchRequest<CachedAPOD> = CachedAPOD.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            if !result.isEmpty {
                let cachedApod = result[0]
                cachedApod.setValue(data, forKey: "apodImage")
            }
            do {
                try context.save()
            } catch {
                print("Failed saving apodImage")
            }
        } catch {
            print("Failed fetching")
        }
    }
    
    func loadCachedApodData() {
        let fetchRequest: NSFetchRequest<CachedAPOD> = CachedAPOD.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            if !result.isEmpty {
                let cachedApod = result[0]
                DispatchQueue.main.async { [weak self] in
                    if cachedApod.apodDate != self?.timeHelper.dateToString(date: Date()) {
                        self?.todayApodTitle.text = "APOD"
                    } else {
                        self?.todayApodTitle.text = "Today's APOD"
                    }
                    self?.apodDate.text = cachedApod.apodDate
                    self?.apodTitle.text = cachedApod.apodTitle
                    self?.apodExplanation.text = cachedApod.apodExplanation
                    if cachedApod.isImage {
                        if let imageData = cachedApod.apodImage {
                            if let image = UIImage(data: imageData) {
                                DispatchQueue.main.async {
                                    self?.apodImage.isHidden = false
                                    self?.apodImage.image = image
                                }
                            }
                        }
                    } else {
                        if let webView = self?.webView, let imageUrl = cachedApod.apodUrl {
                            self?.apodImage.isHidden = true
                            self?.containerView.addSubview(webView)
                            webView.load(URLRequest(url: imageUrl))
                        }
                    }
                }
            }
        } catch {
            print("Failed fetching")
        }
    }
}


