//
//  AppDelegate.swift
//  Netflix
//
//  Created by sunny h on 2021/09/03.
//

import UIKit
import Kingfisher
import AVFoundation
class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    var movies: [Movie] = []
    
    // searchbar 결과들을 viewcontroller 에 위임
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
// 컬렉션 뷰
extension SearchViewController: UICollectionViewDataSource{
    
    // 몇개 넘어오니 ?
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    // 어떻게 표현할꺼니 ?
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 뽑아오는것
       guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as?
                ResultCell else {
        return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        let url = URL(string: movie.thumbnailPath)!
        cell.movieThumbnail.kf.setImage(with: url)
        
    return cell
    }
}
extension SearchViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // movie
        // player vc
        // playver vc + movie
        // presenting player
        
        let movie = movies[indexPath.item]
        let url = URL(string: movie.previewURL)!
        let item = AVPlayerItem(url: url)
        let sb = UIStoryboard(name: "Player", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "PlayerViewController") as! PlayerViewController
        vc.modalPresentationStyle = .fullScreen
        
        vc.player.replaceCurrentItem(with: item)
        present(vc, animated: false,completion: nil)
        
    }
    
}

// 3개 표시, 마진 8 ,아이템간은 10,  섬네일 이미지 7:10
extension SearchViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin: CGFloat = 8
        let itemSpacing: CGFloat = 10
        
        let width = (collectionView.bounds.width - margin * 2 - itemSpacing * 2) / 3
        let height = width * 10 / 7
        return CGSize(width: width, height: height)
    }
    
}

// 컬렉션 뷰 셀

class ResultCell: UICollectionViewCell{
    @IBOutlet weak var movieThumbnail: UIImageView!
}


extension SearchViewController: UISearchBarDelegate{
    
    // 키보드가 올라와 있을때 내려가게 처리
    // searchbar 가 최우선적으로 응답하는 애, 자동적으로 첫번째 응답자가 되는데 컴퓨터한테 첫번쨰 응답하는 것을 사임해라!!
    private func dismissKeyboard(){
        searchBar.resignFirstResponder()
    }
    
    // 다 검색하고 나서 search를 눌렀을때 viewControllerㅇㅔ 알려주는것
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        dismissKeyboard()
        // 검색어가 있는지 확인 밑에까지 내려오지 않으니 search 가되지않음 ( print("--> 검색어 : \(searchTerm)") 이거 작동 안함)
        guard let searchTerm = searchBar.text, searchTerm.isEmpty == false else { return }
        
        // 검색 시작
        // 네트워킹을 통한 검색
        // - 목표 : 서치텀을 가지고 네트워킹을 통해서 영화 검색
        // - 검색 api 가 필요
        // - 결과를 받아올 모델 Movie, response
        
        // - 결과를 받아와서 collectionview로 표현
        
        SearchAPI.search(searchTerm) { movies in
            print("--> 몇개 넘어왔어 ?? : \(movies.count), 첫번째꺼 제록: \(movies.first?.title)")
            // main thread checker가 확인해줌
            DispatchQueue.main.async {
                self.movies = movies
                self.resultCollectionView.reloadData()
            }
        }
        
        print("--> 검색어 : \(searchTerm)")
        
    }
}

// 검색 api

class SearchAPI {
    // @escaping -> 메서드 바깥에서도 실행 될수도 있다
    // static ->  인스턴스를 만들지않아도 사용할수 있다
    static func search(_ term: String, completion: @escaping ([Movie]) -> Void){
        let session = URLSession(configuration: .default)
        
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie")
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term)
        
        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        
        let requestURL = urlComponents.url!
        
        
        let dataTask = session.dataTask(with: requestURL) { data, response, error in
            // 네트워킹을 하고 나서 내려오는 데이터가 data, response, error
            // status code 중에 success range
            let successRange = 200..<300
            
            // 문제가 없으면 데이터 작업, 문제가 있으면 completion에 빈값
            guard error == nil, let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  successRange.contains(statusCode) else { return
                completion([])
            }
            // completion에 빈값
            guard let resultData = data else{
                completion([])
                return
            }
            
            
            // data -> [Movie]
            //let string = String(data: resultData, encoding: .utf8)
            
            let movies = SearchAPI.parseMovies(resultData)
            completion(movies)
         
            //completion([Movie])
        }
        // 네트워크 작업 시작
        dataTask.resume()
    }
    static func parseMovies(_ data: Data) ->[Movie] {
        let decoder = JSONDecoder()
        
        do{
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
        }catch let error {
            print("---> parsing error: \(error.localizedDescription)")
            return []
        }
    }
    
}

// json데이터를 쉽게 파싱
struct Response: Codable {
    let resultCount: Int
    let movies: [Movie]
    // 내려오는 json
    enum CodingKeys: String, CodingKey {
        case resultCount
        case movies = "results"
    }
}

struct  Movie: Codable {
    let title: String
    let director: String
    let thumbnailPath: String
    let previewURL: String
    
    enum CodingKeys: String, CodingKey {
        case title = "trackName"
        case director = "artistName"
        case thumbnailPath = "artworkUrl100"
        case previewURL = "previewUrl"
        }
    }

