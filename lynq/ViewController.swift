import UIKit

// http://stackoverflow.com/questions/642555/how-do-i-calculate-the-azimuth-angle-to-north-between-two-wgs84-coordinates

// http://stackoverflow.com/questions/15890081/calculate-distance-in-x-y-between-two-gps-points#15890610


extension UIBezierPath {
    
    // https://gist.github.com/mwermuth/07825df27ea28f5fc89a
    
    class func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> Self {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
        let points: [CGPoint] = [
            p(0, tailWidth / 2),
            p(tailLength, tailWidth / 2),
            p(tailLength, headWidth / 2),
            p(length, 0),
            p(tailLength, -headWidth / 2),
            p(tailLength, -tailWidth / 2),
            p(0, -tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()
        
        return self.init(cgPath: path)
    }
}



/// all static methods in BobStuff


struct BobStuff {
    struct IOS {
        
        /// these scale a gps point into the screen coordinate system
        static func pointToGPSLocation(_ p:CGPoint,frame:CGRect) -> CGPoint{
            //running +-10 around 0 0 in CLLocation
            let lat = p.x/frame.width * 20 - 10
            let lon = p.y/frame.height * 20 - 10
            return CGPoint(x: lat, y: lon)
        }
    }
    
    struct Kore {
        
        static func degreesToRadians(_ degrees: Double) -> Double { return degrees * M_PI / 180.0 }
        static func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / M_PI }
 
        static func makeView(_ id:String, _ distance: String,_ bearing:CGFloat, _ frame:CGRect,
                             _ tailWidth: Int,_ headWidth: Int,_ headLength: Int,
                             _ color1:UIColor,_ color2:UIColor) -> UIView  {
            let len = frame.height
            let rect = frame
            let centerpoint = CGPoint(x: rect.origin.x + rect.width/2, y: rect.origin.y + rect.height/2)
            let labelframe1 = CGRect(x: 0, y: 1*len/10, width: len, height: len/10)
            let labelframe2 = CGRect(x: 0, y: 8*len/10, width: len, height: len/10)
            
            // arrow always starts in center, but azimuth determines direction
            let radius = len/2
            let azimuth = CGFloat(degreesToRadians(Double(bearing)))
            let endX = cos(azimuth) * radius + centerpoint.x
            let endY = sin(azimuth) * radius + centerpoint.y
            let topoint = CGPoint(x: endX, y: endY)
          
           // print("bearing \(bearing) (\(centerpoint.x), \(centerpoint.y)) radius \(radius) => (\(endX), \(endY))") 
            
            let arrow = UIBezierPath.arrow(from: centerpoint,
                                           to: topoint,
                                           tailWidth: CGFloat(tailWidth),
                                           headWidth: CGFloat(headWidth),
                                           headLength: CGFloat(headLength))
            
            let path = UIBezierPath(ovalIn: rect).cgPath
            let circle = CAShapeLayer()
            circle.path = path
            circle.fillColor = color2.cgColor
            circle.strokeColor = UIColor.red.cgColor
            circle.lineWidth = 2.0

            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = arrow.cgPath
            shapeLayer.fillColor = color1.cgColor
            shapeLayer.strokeColor = color2.cgColor
            shapeLayer.lineWidth = 2.0
            
            let label1 = UILabel(frame:labelframe1)
            label1.text = id
            label1.textAlignment = .center
            label1.textColor = color1
            
            let label2 = UILabel(frame:labelframe2)
            label2.text = distance
            label2.textAlignment = .center
            label2.textColor = color1
            
            let bview = UIView(frame:rect)
            bview.backgroundColor = color2
            bview.layer.addSublayer(circle)
            bview.layer.addSublayer(shapeLayer)
            bview.addSubview(label1)
            bview.addSubview(label2)
            return bview
        }
        static func distanceHaversine(point1 : CGPoint, point2 : CGPoint)->Double {
            
            let lat1rad = degreesToRadians(Double(point1.x))
            let lon1rad = degreesToRadians(Double(point1.y))
            let lat2rad = degreesToRadians(Double(point2.x))
            let lon2rad = degreesToRadians(Double(point2.y))
            let dlon = (lon2rad - lon1rad)
            let dlat  = (lat2rad - lat1rad)
            
            // Haversine formula:
            let R = 6371.0
            let a = sin(dlat/2)*sin(dlat/2) + cos(lat1rad)*cos(lat2rad)*sin(dlon/2)*sin(dlon/2)
            let c = 2 * atan2( sqrt(a), sqrt(1-a) )
            let d = R * c
            return d
        }
        static func distancePlain(point1 : CGPoint, point2 : CGPoint)->Double {
            let lat1rad = (Double(point1.x))
            let lon1rad = (Double(point1.y))
            let lat2rad = (Double(point2.x))
            let lon2rad = (Double(point2.y))
            let dlon = (lon2rad - lon1rad)
            let dlat  = (lat2rad - lat1rad)
            return Double(hypotf(Float(dlon), Float(dlat)))
            
        }
        static func bearingBetweenTwoPoints(point1 : CGPoint, point2 : CGPoint) -> Double {
            
            let lat1rad = degreesToRadians(Double(point1.x))
            let lon1rad = degreesToRadians(Double(point1.y))
            let lat2rad = degreesToRadians(Double(point2.x))
            let lon2rad = degreesToRadians(Double(point2.y))
            
            let dLonrad = lon2rad - lon1rad
            let dLatrad = lat2rad - lat1rad
            
            let radiansBearing = atan2(dLonrad, dLatrad)
            let bearingDegrees =  (radiansToDegrees(radiansBearing) + 360).truncatingRemainder(dividingBy: 360)
            return bearingDegrees
            
        }
    }
}


class ViewController: UIViewController {
    
    // make a circle that works on all size iphones
    let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
    
    // these are set to correct values in viewDidLoad
    
    var zeropt =   CGPoint(x:0,y:0)
    var beginPt =   CGPoint(x:0,y:0)
    var endPt = CGPoint(x:0,y:0)
    
    var controlView: UIView!

    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let location = t.location(in: self.view)
            endPt = location
            buildview()
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let location = t.location(in: self.view)
            endPt = location
            buildview()
        }
    }


    func buildview() {
        // the last place we touched is in "endPt", the center of circle is "beginPt"
        let pt1 = BobStuff.IOS.pointToGPSLocation(beginPt,frame:self.view.frame)
        let pt2 = BobStuff.IOS.pointToGPSLocation(endPt,frame:self.view.frame)
        //checked with http://stackoverflow.com/questions/3809337/calculating-bearing-between-two-cllocationcoordinate2ds
        
        
        let bear = BobStuff.Kore.bearingBetweenTwoPoints(point1: pt1, point2: pt2)

        
        // the Haversine method is no longer used here   
        // let dist = BobStuff.Kore.distanceHaversine(point1: pt1,point2: pt2)
        
        let distance = BobStuff.Kore.distancePlain(point1: pt1,point2: pt2)
        controlView?.removeFromSuperview()
        
        controlView = BobStuff.Kore.makeView("bob",String(format:"%0.2fm ",distance),CGFloat(bear),bounds,10,25,40,.black,.white)        // paste smak in center
        controlView.center = self.view.center
        self.view.addSubview(controlView)
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        buildview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zeropt = CGPoint(x: bounds.origin.x + bounds.width/2,y:bounds.origin.y+bounds.height/2)
        
        beginPt =   CGPoint(x:self.view.frame.width/2,y:self.view.frame.height/2)
        endPt = beginPt
        
        // Do any additional setup after loading the view, typically from a nib.
        buildview()
    }
}

