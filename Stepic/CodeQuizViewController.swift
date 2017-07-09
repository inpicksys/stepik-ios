//
//  CodeQuizViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 22.06.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import FLKAutoLayout
import Highlightr

class CodeQuizViewController: QuizViewController {

    var limitsLabel: UILabel = UILabel()
    var toolbarView: CodeQuizToolbarView = CodeQuizToolbarView(frame: CGRect.zero)
    var codeTextView: UITextView = UITextView()
    
    let toolbarHeight : CGFloat = 44
    let codeTextViewHeight : CGFloat = 180
    let limitsLabelHeight : CGFloat = 40
    
    let languagePicker = CodeLanguagePickerViewController(nibName: "PickerViewController", bundle: nil) as CodeLanguagePickerViewController
    
    var highlightr : Highlightr!
    let textStorage = CodeAttributedString()
    
    let playgroundManager = CodePlaygroundManager()
    var currentCode : String = ""
    
    var tabSize: Int = 0
    
    var language: String = "" {
        didSet {
            textStorage.language = Languages.highligtrFromStepik[language.lowercased()]
            if let limit = step.options?.limit(language: language) {
                setLimits(time: limit.time, memory: limit.memory)
            }
            
            if let template = step.options?.template(language: language, userGenerated: false) {
                tabSize = playgroundManager.countTabSize(text: template.templateString)
            }
            
            //setting up input accessory view
            codeTextView.inputAccessoryView = InputAccessoryBuilder.buildAccessoryView(language: language, tabAction: {
                [weak self] in
                guard let s = self else { return }
                s.insertAtCurrentPosition(symbols: String(repeating: " ", count: s.tabSize))
            }, insertStringAction: {
                [weak self]
                symbols in
                self?.insertAtCurrentPosition(symbols: symbols)
            })
            
            if let userTemplate = step.options?.template(language: language, userGenerated: true) {
                codeTextView.text = userTemplate.templateString
                currentCode = userTemplate.templateString
                return
            }
            if let template = step.options?.template(language: language, userGenerated: false) {
                codeTextView.text = template.templateString
                currentCode = template.templateString
                return
            }
        }
    }
    
    fileprivate func insertAtCurrentPosition(symbols: String) {
        if let selectedRange = codeTextView.selectedTextRange {
            let cursorPosition = codeTextView.offset(from: codeTextView.beginningOfDocument, to: selectedRange.start)
            var text = codeTextView.text!
            text.insert(contentsOf: symbols.characters, at: text.index(text.startIndex, offsetBy: cursorPosition))
            codeTextView.text = text
            codeTextView.selectedTextRange = textRangeFrom(position: cursorPosition + symbols.characters.count)
            
            analyzeAndComplete(textView: codeTextView)
        }
    }
    
    override var submissionAnalyticsParams: [String : Any]? {
        guard let step = step else {
            return nil
        }
        var params: [String: Any]? = ["stepId" : step.id, "language": language]
        
        if let course = step.lesson?.unit?.section?.course?.id  {
            params?["course"] = course
        }
        
        return params
    }
    
    override var expectedQuizHeight : CGFloat {
        return toolbarHeight + codeTextViewHeight + limitsLabelHeight + 16
    }
    
    fileprivate func setupConstraints() {
        self.containerView.addSubview(limitsLabel)
        self.containerView.addSubview(toolbarView)
        self.containerView.addSubview(codeTextView)
        limitsLabel.alignTopEdge(with: self.containerView, predicate: "8")
        limitsLabel.alignLeading("8", trailing: "0", to: self.containerView)
        limitsLabel.constrainHeight("\(limitsLabelHeight)")
        toolbarView.constrainTopSpace(to: self.limitsLabel, predicate: "8")
        toolbarView.alignLeading("0", trailing: "0", to: self.containerView)
        toolbarView.constrainBottomSpace(to: self.codeTextView, predicate: "8")
        toolbarView.constrainHeight("\(toolbarHeight)")
        codeTextView.alignLeading("0", trailing: "0", to: self.containerView)
        codeTextView.alignBottomEdge(with: self.containerView, predicate: "0")
        codeTextView.constrainHeight("\(codeTextViewHeight)")
    }
    
    fileprivate func setLimits(time: Double, memory: Double) {
        
        let attTimeLimit = NSAttributedString(string: "Time limit: ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
        let attMemoryLimit = NSAttributedString(string: "Memory limit: ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
        let attTime = NSAttributedString(string: "\(time)\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15)])
        let attMemory = NSAttributedString(string: "\(memory)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15)])

        let result = NSMutableAttributedString(attributedString: attTimeLimit)
        result.append(attTime)
        result.append(attMemoryLimit)
        result.append(attMemory)
        limitsLabel.numberOfLines = 2
        limitsLabel.attributedText = result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        codeTextView = UITextView(frame: CGRect.zero, textContainer: textContainer)
        codeTextView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        codeTextView.autocorrectionType = UITextAutocorrectionType.no
        codeTextView.autocapitalizationType = UITextAutocapitalizationType.none
        codeTextView.textColor = UIColor(white: 0.8, alpha: 1.0)
        highlightr = textStorage.highlightr
        highlightr.setTheme(to: "Androidstudio")
        codeTextView.backgroundColor = highlightr.theme.themeBackgroundColor

        setupConstraints()
        
        toolbarView.delegate = self
        
        guard let options = step.options else {
            return
        }
        
        languagePicker.languages = options.languages

        codeTextView.delegate = self
        
        submissionPressedBlock = {
            [weak self] in
            self?.codeTextView.resignFirstResponder()
        }
    }
    
    func showPicker() {
        isSubmitButtonHidden = true
        addChildViewController(languagePicker)
        view.addSubview(languagePicker.view)
        languagePicker.view.align(to: containerView)
        languagePicker.backButton.isHidden = true
        languagePicker.selectedBlock = {
            [weak self] in
            guard let s = self else { return }
            s.language = s.languagePicker.selectedData
            AnalyticsReporter.reportEvent(AnalyticsEvents.Code.languageChosen, parameters: ["size": "standard", "language": s.language])
            s.languagePicker.removeFromParentViewController()
            s.languagePicker.view.removeFromSuperview()
            s.isSubmitButtonHidden = false
            s.delegate?.needsHeightUpdate(s.heightWithoutQuiz + s.expectedQuizHeight, animated: true, breaksSynchronizationControl: false)
        }
    }
    
    override func updateQuizAfterAttemptUpdate() {
        guard step.options != nil else {
            return
        }
        setQuizControls(enabled: true)
    }
    
    fileprivate func setQuizControls(enabled: Bool) {
        codeTextView.isEditable = enabled
        toolbarView.fullscreenButton.isEnabled = enabled
        toolbarView.resetButton.isEnabled = enabled
        toolbarView.languageButton.isEnabled = enabled
    }
    
    override func updateQuizAfterSubmissionUpdate(reload: Bool = true) {
        if submission?.status == "correct" {
            setQuizControls(enabled: false)
        } else {
            setQuizControls(enabled: true)
        }
        
        guard let reply = submission?.reply as? CodeReply else {
            showPicker()
            return
        }
        
        language = reply.language
        codeTextView.text = reply.code
        currentCode = reply.code
    }
    
    override var needsToRefreshAttemptWhenWrong : Bool {
        return false
    }
    
    override func getReply() -> Reply {
        return CodeReply(code: codeTextView.text ?? "", language: language)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    var suggestionsController: CodeSuggestionsTableViewController? = nil
    var isSuggestionsViewPresented : Bool {
        return suggestionsController != nil
    }
}

extension CodeQuizViewController : CodeQuizToolbarDelegate {
    func changeLanguagePressed() {
        showPicker()
    }
    
    func fullscreenPressed() {
        guard let options = step.options else {
            return
        }
        
        AnalyticsReporter.reportEvent(AnalyticsEvents.Code.fullscreenPressed, parameters: ["size": "standard"])
        
        let fullscreen = FullscreenCodeQuizViewController(nibName: "FullscreenCodeQuizViewController", bundle: nil)
        fullscreen.options = options
        fullscreen.language = language
        fullscreen.onDismissBlock = {
            [weak self]
            newLanguage, newText in
            self?.language = newLanguage
            self?.codeTextView.text = newText
            self?.currentCode = newText
        }
        
        present(fullscreen, animated: true, completion: nil)
    }
    
    func resetPressed() {
        guard let options = step.options else {
            return
        }
        
        AnalyticsReporter.reportEvent(AnalyticsEvents.Code.resetPressed, parameters: ["size": "standard"])
        
        if let userTemplate = options.template(language: language, userGenerated: true) {
            CoreDataHelper.instance.deleteFromStore(userTemplate)
        }
        if let template = options.template(language: language, userGenerated: false) {
            codeTextView.text = template.templateString
            currentCode = template.templateString
        }
        CoreDataHelper.instance.save()
    }
    
    fileprivate func hideSuggestions() {
        //TODO: hide suggestions view here
        self.suggestionsController?.view.removeFromSuperview()
        self.suggestionsController?.removeFromParentViewController()
        self.suggestionsController = nil
    }
    
    fileprivate func presentSuggestions(suggestions: [String], prefix: String, cursorPosition: Int) {
        //TODO: If suggestions are presented, only change the data there, otherwise instantiate and add suggestions view
        if !isSuggestionsViewPresented {
            suggestionsController = CodeSuggestionsTableViewController(nibName: "CodeSuggestionsTableViewController", bundle: nil)
            self.addChildViewController(suggestionsController!)
            self.codeTextView.addSubview(suggestionsController!.view)
        }
        

        suggestionsController?.suggestions = suggestions
        suggestionsController?.prefix = prefix
        
        if let selectedRange = codeTextView.selectedTextRange {
            // `caretRect` is in the `codeTextView` coordinate space.
            let caretRect = codeTextView.caretRect(for: selectedRange.end)
            
            var suggestionsFrameMinX = caretRect.minX
            var suggestionsFrameMinY = caretRect.maxY
            
            let suggestionsHeight = suggestionsController!.suggestionsHeight

            //check if we need to move suggestionsFrame
            if suggestionsFrameMinY + suggestionsHeight > (codeTextView.frame.maxY - codeTextView.frame.origin.y) {
                suggestionsFrameMinY = caretRect.minY - suggestionsHeight
            }
            
            if suggestionsFrameMinX + 80 > (codeTextView.frame.maxX - codeTextView.frame.origin.x) {
                suggestionsFrameMinX = (codeTextView.frame.maxX - codeTextView.frame.origin.x - 85)
            }
            
            let rect = CGRect(x: suggestionsFrameMinX, y: suggestionsFrameMinY, width: 80, height: suggestionsHeight)
            suggestionsController?.view.frame = rect
        }
    }
    
    fileprivate func analyzeAndComplete(textView: UITextView) {
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            
            let analyzed = playgroundManager.analyze(currentText: textView.text, previousText: currentCode, cursorPosition: cursorPosition, language: language, tabSize: tabSize)
            
            textView.text = analyzed.text
            textView.selectedTextRange = textRangeFrom(position: analyzed.position)
            if let autocomplete = analyzed.autocomplete {
                if autocomplete.suggestions.count == 0 {
                    hideSuggestions()
                } else {
                    presentSuggestions(suggestions: autocomplete.suggestions, prefix: autocomplete.prefix, cursorPosition: analyzed.position)
                }
            } else {
                hideSuggestions()
            }
        }
        
        currentCode = textView.text
    }
}

extension CodeQuizViewController : UITextViewDelegate {
    
    fileprivate func textRangeFrom(position: Int) -> UITextRange {
        let firstCharacterPosition = codeTextView.beginningOfDocument
        let characterPosition = codeTextView.position(from: firstCharacterPosition, offset: position)!
        let characterRange = codeTextView.textRange(from: characterPosition, to: characterPosition)!
        return characterRange
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let options = step.options else {
            return
        }
        
        analyzeAndComplete(textView: codeTextView)
        
        if let userTemplate = options.template(language: language, userGenerated: true) {
            userTemplate.templateString = textView.text
        } else {
            let newTemplate = CodeTemplate(language: language, template: textView.text)
            newTemplate.isUserGenerated = true
            options.templates += [newTemplate]
        }
        
        CoreDataHelper.instance.save()
    }
}
