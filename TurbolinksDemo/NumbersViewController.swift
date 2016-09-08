import UIKit

private let CellIdentifier = "CellIdentifier"

class NumbersViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Numbers"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)

        let number = indexPath.row + 1
        cell.textLabel?.text = "Row \(number)"

        return cell
    }
}
