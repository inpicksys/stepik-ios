//
//  CodeSuggestionsTableViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 08.07.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

protocol CodeSuggestionDelegate: class {
    func didSelectSuggestion(suggestion: String, prefix: String)
}

class CodeSuggestionsTableViewController: UITableViewController {
    
    var suggestions: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var prefix: String = "" {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate let suggestionHeight: CGFloat = 20
    fileprivate let maxSuggestionCount = 5
    
    weak var delegate: CodeSuggestionDelegate?
    
    var suggestionsHeight: CGFloat {
        return suggestionHeight * CGFloat(min(maxSuggestionCount, suggestions.count))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "CodeSuggestionTableViewCell", bundle: nil), forCellReuseIdentifier: "CodeSuggestionTableViewCell")

        self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CodeSuggestionTableViewCell", for: indexPath) as? CodeSuggestionTableViewCell else {
            return UITableViewCell()
        }
        
        cell.setSuggestion(suggestions[indexPath.row], prefixLength: prefix.characters.count)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectSuggestion(suggestion: suggestions[indexPath.row], prefix: prefix)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
