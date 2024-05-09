//
//  CaseByDistrictMap.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 29/3/2024.
//

import SwiftUI
import MapKit
import CoreLocation

struct CaseByDistrictMap: View {
    @State var polygons: [MKPolygon] = []
    let strokeColor: Color = .primary
    let lineWidth: CGFloat = 1
    let foregrounds: [some ShapeStyle] = Array(repeating: Color.random.opacity(0.6), count: 18)
    var body: some View {
        Map(
            bounds: MapCameraBounds(
                centerCoordinateBounds: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: 22.37908,
                        longitude: 114.10598
                    ),
                    latitudinalMeters: 100000,
                    longitudinalMeters: 100000
                ),
                minimumDistance: 50000)
        ) {
            if !polygons.isEmpty {
                ForEach(0...(polygons.count-1), id: \.self) { (index: Int) in
                    let polygon: MKPolygon = self.polygons[index]
                    let foreground = foregrounds[index]
                    MapPolygon(polygon)
                        .mapOverlayLevel(level: .aboveLabels)
                        .foregroundStyle(foreground)
                        .stroke(strokeColor, lineWidth: lineWidth)
                }
            }
            ForEach(0...17, id: \.self) { (index: Int) in
                let coor: (Double, Double) = COORDINATES[index]
                let latitude: Double = coor.0
                let longitude: Double = coor.1
                let district: String = DISTRICTS[index]
                Annotation(
                    "\(latitude),\(longitude)",
                    coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )) {
                    Text(district)
                        .bold()
                        .foregroundStyle(.primary)
                }
                    .annotationTitles(.hidden)
            }
        }
        .overlay(alignment: .topLeading) {
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 300)
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
//        let file: String = "converted.json"
        let file: String = "hksar_18_district_boundary.json"
        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        
        guard let geoJsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        
        let jsonDecoder = JSONDecoder()
        
        if let features = try? MKGeoJSONDecoder().decode(geoJsonData) as? [MKGeoJSONFeature] {
            //            print(features[0].geometry[0])
            self.polygons = features.compactMap({ $0.geometry.first as? MKPolygon })
            
//            self.districts = features
//                .compactMap({ $0.properties })
//                .compactMap({ try? jsonDecoder.decode(District.self, from: $0) })
        } else {
            print("Failed to parse to [MKGeoJSONFeature]")
        }
    }
    
    func getCoordinatesInEPSG3857(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let longitudeInEPSG4326: Double = coordinate.longitude
        let latitudeInEPSG4326: Double = coordinate.latitude
        let longitudeInEPSG3857 = (longitudeInEPSG4326 * 20037508.34 / 180)
        let latitudeInEPSG3857 = (log(tan((90 + latitudeInEPSG4326) * Double.pi / 360)) / (Double.pi / 180)) * (20037508.34 / 180)

        return CLLocationCoordinate2D(latitude: latitudeInEPSG3857, longitude: longitudeInEPSG3857)
    }
}

//extension CaseByDistrictMap {
//    struct District: Decodable {
//        let eng: String
//        let chi: String
//        
//        enum CodingKeys: String, CodingKey {
//            case eng = "District"
//            case chi = "地區"
//        }
//    }
//}

#Preview {
    CaseByDistrictMap()
}
