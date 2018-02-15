//
//  ToDoViewController.swift
//  TodoSwift
//
//  Created by Cyril Chandelier on 31/10/15.
//  Copyright © 2015 Cyril Chandelier. All rights reserved.
//

import UIKit
import CoreData


class ToDoViewController: UITableViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate, ToDoCellDelegate
{
    // Outlets
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var clearBarButtonItem: UIBarButtonItem!
    @IBOutlet var taskTextField: UITextField!
    @IBOutlet var tableFooterView: UIView!
    @IBOutlet var itemsCountLabel: UILabel!
    
    // Data
    private var frc: NSFetchedResultsController<NSFetchRequestResult>!
    private var predicate: NSPredicate? {
        didSet {
            refreshData()
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Accessibility
        tableView.accessibilityLabel = Accessibility.TaskList.localizedLabel
        taskTextField.accessibilityLabel = Accessibility.CreateNewTaskTextField.localizedLabel
        clearBarButtonItem.accessibilityLabel = Accessibility.ClearCompletedTasksButton.localizedLabel
        
        // Background color
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background_pattern")!)
        
        // i18n
        taskTextField.placeholder = NSLocalizedString("todo_list.task_placeholder", comment: "Add task placeholder")
        segmentedControl.setTitle(NSLocalizedString("todo_list.filter.all", comment: "Filter: All"), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString("todo_list.filter.active", comment: "Filter: Active"), forSegmentAt: 1)
        segmentedControl.setTitle(NSLocalizedString("todo_list.filter.completed", comment: "Filter: Completed"), forSegmentAt: 2)
        
        taskTextField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)

        // Refresh
        refreshData()
        refreshUI()
    }
    
    func enterPressed(){
        //do something with typed text if needed
        taskTextField.resignFirstResponder()
    }
    
    // MARK: - Data management
    
    func refreshData()
    {
        // Prepare fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: TaskEntityName)
        fetchRequest.sortDescriptors = Task.sortDescriptors()
        fetchRequest.predicate = predicate
        
        // Create FRC
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure frc delegate
        frc.delegate = self
        
        // Perform data fetch
        do {
            try frc.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        // Refresh UI
        refreshUI();
    }
    
    func refreshUI()
    {
        if !isViewLoaded {
            return
        }
        
        // Reload table view if loaded
        tableView.reloadData()
        
        // Refresh table view footer
        refreshTableFooterView()
    }
    
    func refreshTableFooterView()
    {
        // Query only active tasks
        let itemsCount = TaskService.taskList(predicate: Task.activePredicate()).count
        
        // Build attributed string
        let itemsCountString = NSMutableAttributedString()
        itemsCountString.append(NSAttributedString(string: String(itemsCount), attributes: [
            NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14.0)
            ]))
        itemsCountString.append(NSAttributedString(string: (itemsCount == 1 ? NSLocalizedString("todo_list.item_left", comment: "Singular items left") : NSLocalizedString("todo_list.items_left", comment: "Plural items left")), attributes: [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14.0)
            ]))
        
        // Update label
        itemsCountLabel.attributedText = itemsCountString
        
        // Assign table footer view
        tableView.tableFooterView = tableFooterView
    }
    
    // MARK: - UITableViewDataSource methods
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        guard let sections = frc.sections else {
            return 0
        }
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = frc.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let task = frc.object(at: indexPath as IndexPath) as! Task
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCellIdentifier) as! ToDoCell
        cell.delegate = self
        cell.configureWithTask(task: task)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate methods
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let task = frc.object(at: indexPath as IndexPath)
            TaskService.deleteTask(task: task as! Task)
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate methods
    
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        refreshUI()
    }
    
    // MARK: - UITextFieldDelegate methods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        NSLog("textFieldDidEndEditing")


    
    //private func textFieldShouldReturn(textField: UITextField) -> Bool
    //{
      //  NSLog("textFieldShouldReturn")
        //return true
        
        let content = self.taskTextField.text
    
        // Create a task if entered string is not empty
        
        if((content) != nil)
        {
            // we will create a task and then push it the service
            let createdTask = TaskService.createTask(content: content!)
            
            let createTaskAsDictionary = ["title":createdTask?.label ?? "empty","completed":false] as [String : Any]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: createTaskAsDictionary, options: .prettyPrinted)
                
                let requestURL = URL.init(string: "rest/todos")
                let request = URLRequest.init(url: requestURL!)
                
                let uploadtask = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
                    if let error = error {
                        print ("error: \(error)")
                        return
                    }
                    guard let response = response as? HTTPURLResponse,
                        (200...299).contains(response.statusCode) else {
                            print ("server error")
                            return
                    }
                    if let mimeType = response.mimeType,
                        mimeType == "application/json",
                        let data = data,
                        let dataString = String(data: data, encoding: .utf8) {
                        print ("got data: \(dataString)")
                    }
                }
                uploadtask.resume()

                // here "jsonData" is the dictionary encoded in JSON data
                
                //let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
                // here "decoded" is of type `Any`, decoded from JSON data
                
                // you can now cast it with the right type
                //if let dictFromJSON = decoded as? [String:String] {
                    // use dictFromJSON
                //}
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Reset text field
        taskTextField.text = ""
        
        // Close keyboard
        taskTextField.resignFirstResponder()
        
        refreshData()
    }
    
    // MARK: - ToDoCellDelegate methdos
    
    func toDoCell(cell: ToDoCell, didToggleCompletionForTask task: Task)
    {
        TaskService.toggleTask(task: task)
    }
    
    func toDoCell(cell: ToDoCell, didEditContent content: String?, forTask task: Task)
    {
        guard let content = content else {
            return
        }
        
        TaskService.updateTask(task: task, content: content)
    }
    
    // MARK: - UI Actions
    
    @IBAction func filter(sender: UISegmentedControl)
    {
        // Update predicate
        switch(sender.selectedSegmentIndex) {
        case 1:
            predicate = Task.activePredicate()
        case 2:
            predicate = Task.completedPredicate()
        case 0:
            fallthrough
        default:
            predicate = nil
        }
        
        // Refresh data
        refreshData()
    }
    
    @IBAction func clearCompleted()
    {
        TaskService.clearCompletedTasks()
    }
    
    // MARK: - Memory management
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
}

