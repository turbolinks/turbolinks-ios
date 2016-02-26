import UIKit

private let CellIdentifier = "CellIdentifier"

class NumbersViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Numbers"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)

        let number = indexPath.row + 1
        cell.textLabel?.text = "Row \(number)"

        return cell
    }
}
