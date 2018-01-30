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
        
        // Refresh
        refreshData()
        refreshUI()
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        guard let sections = frc.sections else {
            return 0
        }
        return sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = frc.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
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
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
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
    
    private func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        guard let content = textField.text else {
            return false
        }
        
        // Create a task if entered string is not empty
        
        if(content.count > 0)
        {
            TaskService.createTask(content: content)
        }
        
        // Reset text field
        textField.text = ""
        
        // Close keyboard
        textField.resignFirstResponder()
        
        return true
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

