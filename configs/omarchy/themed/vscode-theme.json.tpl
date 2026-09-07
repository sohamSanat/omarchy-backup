{
    "name": "Omarchy",
    "$schema": "vscode://schemas/color-theme",
    "type": "{{ theme_type }}",
    "semanticHighlighting": true,
    "semanticTokenColors": {
    "newOperator": "{{ magenta }}",
    "stringLiteral": "{{ bright_green }}",
    "customLiteral": "{{ bright_green }}",
    "numberLiteral": "{{ orange }}",
    "keyword": "{{ magenta }}",
    "keyword.control": "{{ magenta }}",
    "keyword.control.flow": {
        "foreground": "{{ magenta }}",
        "fontStyle": "italic"
    },
    "keyword.control.import": "{{ magenta }}",
    "keyword.control.export": "{{ magenta }}",
    "keyword.control.from": "{{ magenta }}",
    "keyword.control.as": "{{ magenta }}",
    "keyword.operator": "{{ cyan }}",
    "class": "{{ bright_yellow }}",
    "class.declaration": {
        "foreground": "{{ bright_yellow }}",
        "fontStyle": "bold"
    },
    "class.defaultLibrary": "{{ bright_yellow }}",
    "class.builtin": "{{ bright_yellow }}",
    "struct": "{{ bright_yellow }}",
    "struct.declaration": {
        "foreground": "{{ bright_yellow }}",
        "fontStyle": "bold"
    },
    "interface": "{{ bright_yellow }}",
    "interface.declaration": {
        "foreground": "{{ bright_yellow }}",
        "fontStyle": "bold"
    },
    "type": "{{ bright_yellow }}",
    "type.declaration": "{{ bright_yellow }}",
    "type.defaultLibrary": "{{ bright_yellow }}",
    "type.builtin": "{{ bright_yellow }}",
    "builtinType": "{{ bright_yellow }}",
    "typeParameter": {
        "foreground": "{{ bright_yellow }}",
        "fontStyle": "italic"
    },
    "enum": "{{ bright_yellow }}",
    "enum.declaration": {
        "foreground": "{{ bright_yellow }}",
        "fontStyle": "bold"
    },
    "enumMember": "{{ orange }}",
    "enumMember.declaration": "{{ orange }}",
    "function": "{{ cyan }}",
    "function.declaration": {
        "foreground": "{{ cyan }}",
        "fontStyle": "bold"
    },
    "function.defaultLibrary": "{{ bright_cyan }}",
    "function.builtin": "{{ bright_cyan }}",
    "method": "{{ cyan }}",
    "method.declaration": {
        "foreground": "{{ cyan }}",
        "fontStyle": "bold"
    },
    "method.defaultLibrary": "{{ bright_cyan }}",
    "method.builtin": "{{ bright_cyan }}",
    "method.magic": "{{ bright_cyan }}",
    "magicFunction": "{{ bright_cyan }}",
    "decorator": {
        "foreground": "{{ magenta }}",
        "fontStyle": "italic"
    },
    "decorator.builtin": {
        "foreground": "{{ magenta }}",
        "fontStyle": "italic"
    },
    "parameter": {
        "foreground": "{{ orange }}",
        "fontStyle": "italic"
    },
    "parameter.declaration": {
        "foreground": "{{ orange }}",
        "fontStyle": "italic"
    },
    "selfParameter": {
        "foreground": "{{ red }}",
        "fontStyle": "italic"
    },
    "clsParameter": {
        "foreground": "{{ red }}",
        "fontStyle": "italic"
    },
    "variable": "{{ foreground }}",
    "variable.declaration": "{{ foreground }}",
    "variable.readonly": "{{ bright_yellow }}",
    "variable.defaultLibrary": "{{ bright_cyan }}",
    "variable.builtin": "{{ red }}",
    "property": "{{ bright_blue }}",
    "property.declaration": "{{ bright_blue }}",
    "property.readonly": "{{ bright_blue }}",
    "namespace": "{{ bright_blue }}",
    "namespace.declaration": "{{ bright_blue }}",
    "macro": "{{ bright_cyan }}",
    "string": "{{ bright_green }}",
    "number": "{{ orange }}",
    "boolean": {
        "foreground": "{{ orange }}",
        "fontStyle": "bold"
    },
    "regexp": "{{ bright_cyan }}",
    "operator": "{{ cyan }}",
    "comment": {
        "foreground": "{{ muted }}",
        "fontStyle": "italic"
    },
    "comment.documentation": {
        "foreground": "{{ muted }}",
        "fontStyle": "italic"
    },
    "*.readonly": {
        "foreground": "{{ bright_yellow }}"
    },
    "*.deprecated": {
        "fontStyle": "strikethrough"
    }
},
    "colors": {
        "foreground": "{{ foreground }}",
        "disabledForeground": "{{ dark_foreground }}",
        "focusBorder": "{{ accent }}80",
        "widget.shadow": "{{ background }}80",
        "selection.background": "{{ selection_background }}80",
        "descriptionForeground": "{{ muted }}",
        "errorForeground": "{{ red }}",
        "icon.foreground": "{{ foreground }}",
        "sash.hoverBorder": "{{ accent }}",

        "textBlockQuote.background": "{{ background }}",
        "textBlockQuote.border": "{{ accent }}",
        "textCodeBlock.background": "{{ background }}",
        "textLink.activeForeground": "{{ bright_blue }}",
        "textLink.foreground": "{{ blue }}",
        "textPreformat.foreground": "{{ cyan }}",
        "textPreformat.background": "{{ background }}",
        "textSeparator.foreground": "{{ muted }}",

        "toolbar.hoverBackground": "{{ background }}",
        "toolbar.activeBackground": "{{ muted }}",

        "button.background": "{{ accent }}",
        "button.foreground": "{{ background }}",
        "button.hoverBackground": "{{ blue }}",
        "button.secondaryForeground": "{{ foreground }}",
        "button.secondaryBackground": "{{ muted }}",
        "button.secondaryHoverBackground": "{{ background }}",
        "button.border": "{{ accent }}20",
        "checkbox.background": "{{ background }}",
        "checkbox.foreground": "{{ foreground }}",
        "checkbox.border": "{{ muted }}",
        "checkbox.selectBackground": "{{ accent }}",
        "checkbox.selectBorder": "{{ accent }}",

        "dropdown.background": "{{ background }}",
        "dropdown.listBackground": "{{ background }}",
        "dropdown.border": "{{ muted }}",
        "dropdown.foreground": "{{ foreground }}",

        "input.background": "{{ background }}",
        "input.border": "{{ muted }}",
        "input.foreground": "{{ foreground }}",
        "input.placeholderForeground": "{{ muted }}",
        "inputOption.activeBackground": "{{ accent }}40",
        "inputOption.activeBorder": "{{ accent }}",
        "inputOption.activeForeground": "{{ foreground }}",
        "inputOption.hoverBackground": "{{ muted }}",
        "inputValidation.errorBackground": "{{ red }}20",
        "inputValidation.errorForeground": "{{ red }}",
        "inputValidation.errorBorder": "{{ red }}",
        "inputValidation.infoBackground": "{{ blue }}20",
        "inputValidation.infoForeground": "{{ blue }}",
        "inputValidation.infoBorder": "{{ blue }}",
        "inputValidation.warningBackground": "{{ yellow }}20",
        "inputValidation.warningForeground": "{{ yellow }}",
        "inputValidation.warningBorder": "{{ yellow }}",

        "scrollbar.shadow": "{{ background }}",
        "scrollbarSlider.activeBackground": "{{ accent }}80",
        "scrollbarSlider.background": "{{ muted }}40",
        "scrollbarSlider.hoverBackground": "{{ muted }}80",

        "badge.background": "{{ accent }}",
        "badge.foreground": "{{ background }}",

        "progressBar.background": "{{ accent }}",

        "list.activeSelectionBackground": "{{ accent }}30",
        "list.activeSelectionForeground": "{{ foreground }}",
        "list.activeSelectionIconForeground": "{{ foreground }}",
        "list.dropBackground": "{{ accent }}20",
        "list.focusBackground": "{{ accent }}20",
        "list.focusForeground": "{{ foreground }}",
        "list.focusOutline": "{{ accent }}60",
        "list.highlightForeground": "{{ accent }}",
        "list.hoverBackground": "{{ background }}",
        "list.hoverForeground": "{{ foreground }}",
        "list.inactiveSelectionBackground": "{{ muted }}40",
        "list.inactiveSelectionForeground": "{{ foreground }}",
        "list.inactiveFocusBackground": "{{ muted }}40",
        "list.inactiveFocusOutline": "{{ muted }}",
        "list.invalidItemForeground": "{{ red }}",
        "list.errorForeground": "{{ red }}",
        "list.warningForeground": "{{ yellow }}",
        "listFilterWidget.background": "{{ background }}",
        "listFilterWidget.outline": "{{ accent }}",
        "listFilterWidget.noMatchesOutline": "{{ red }}",
        "list.filterMatchBackground": "{{ accent }}30",
        "list.filterMatchBorder": "{{ accent }}",
        "tree.indentGuidesStroke": "{{ muted }}",
        "tree.inactiveIndentGuidesStroke": "{{ muted }}60",
        "tree.tableColumnsBorder": "{{ muted }}",
        "tree.tableOddRowsBackground": "{{ background }}40",

        "activityBar.background": "{{ background }}",
        "activityBar.dropBorder": "{{ accent }}",
        "activityBar.foreground": "{{ foreground }}",
        "activityBar.inactiveForeground": "{{ muted }}",
        "activityBar.border": "{{ background }}",
        "activityBarBadge.background": "{{ accent }}",
        "activityBarBadge.foreground": "{{ background }}",
        "activityBar.activeBorder": "{{ accent }}",
        "activityBar.activeBackground": "{{ background }}40",

        "sideBar.background": "{{ background }}",
        "sideBar.foreground": "{{ foreground }}",
        "sideBar.border": "{{ background }}",
        "sideBar.dropBackground": "{{ accent }}20",
        "sideBarTitle.foreground": "{{ foreground }}",
        "sideBarSectionHeader.background": "{{ background }}",
        "sideBarSectionHeader.foreground": "{{ foreground }}",
        "sideBarSectionHeader.border": "{{ muted }}40",

        "minimap.findMatchHighlight": "{{ accent }}80",
        "minimap.selectionHighlight": "{{ accent }}60",
        "minimap.errorHighlight": "{{ red }}",
        "minimap.warningHighlight": "{{ yellow }}",
        "minimap.background": "{{ background }}",
        "minimap.selectionOccurrenceHighlight": "{{ accent }}40",
        "minimap.foregroundOpacity": "{{ background }}c0",
        "minimapSlider.background": "{{ muted }}20",
        "minimapSlider.hoverBackground": "{{ muted }}40",
        "minimapSlider.activeBackground": "{{ muted }}60",
        "minimapGutter.addedBackground": "{{ green }}",
        "minimapGutter.modifiedBackground": "{{ orange }}",
        "minimapGutter.deletedBackground": "{{ red }}",

        "editorGroup.border": "{{ muted }}40",
        "editorGroup.dropBackground": "{{ accent }}20",
        "editorGroup.dropIntoPromptForeground": "{{ foreground }}",
        "editorGroup.dropIntoPromptBackground": "{{ background }}",
        "editorGroup.dropIntoPromptBorder": "{{ accent }}",
        "editorGroupHeader.noTabsBackground": "{{ background }}",
        "editorGroupHeader.tabsBackground": "{{ background }}",
        "editorGroupHeader.tabsBorder": "{{ background }}",
        "editorGroupHeader.border": "{{ background }}",
        "editorGroup.emptyBackground": "{{ background }}",
        "tab.activeBackground": "{{ background }}",
        "tab.unfocusedActiveBackground": "{{ background }}",
        "tab.activeForeground": "{{ foreground }}",
        "tab.activeBorder": "{{ accent }}",
        "tab.activeBorderTop": "{{ accent }}",
        "tab.unfocusedActiveBorder": "{{ muted }}",
        "tab.unfocusedActiveBorderTop": "{{ muted }}",
        "tab.border": "{{ background }}",
        "tab.inactiveBackground": "{{ background }}",
        "tab.inactiveForeground": "{{ muted }}",
        "tab.unfocusedActiveForeground": "{{ foreground }}",
        "tab.unfocusedInactiveForeground": "{{ muted }}",
        "tab.hoverBackground": "{{ muted }}40",
        "tab.unfocusedHoverBackground": "{{ muted }}40",
        "tab.hoverForeground": "{{ foreground }}",
        "tab.hoverBorder": "{{ accent }}40",
        "tab.activeModifiedBorder": "{{ yellow }}",
        "tab.inactiveModifiedBorder": "{{ yellow }}80",
        "tab.unfocusedActiveModifiedBorder": "{{ yellow }}80",
        "tab.unfocusedInactiveModifiedBorder": "{{ yellow }}60",
        "tab.lastPinnedBorder": "{{ muted }}",
        "editorPane.background": "{{ background }}",

        "editor.background": "{{ background }}",
        "editor.foreground": "{{ foreground }}",
        "editorLineNumber.foreground": "{{ muted }}",
        "editorLineNumber.activeForeground": "{{ foreground }}",
        "editorLineNumber.dimmedForeground": "{{ muted }}80",
        "editorCursor.background": "{{ background }}",
        "editorCursor.foreground": "{{ bright_foreground }}",
        "editor.selectionBackground": "{{ selection_background }}60",
        "editor.selectionForeground": "{{ selection_foreground }}",
        "editor.inactiveSelectionBackground": "{{ selection_background }}30",
        "editor.selectionHighlightBackground": "{{ accent }}20",
        "editor.selectionHighlightBorder": "{{ accent }}40",
        "editor.wordHighlightBackground": "{{ accent }}20",
        "editor.wordHighlightBorder": "{{ accent }}40",
        "editor.wordHighlightStrongBackground": "{{ accent }}30",
        "editor.wordHighlightStrongBorder": "{{ accent }}60",
        "editor.wordHighlightTextBackground": "{{ accent }}15",
        "editor.wordHighlightTextBorder": "{{ accent }}30",
        "editor.findMatchBackground": "{{ yellow }}40",
        "editor.findMatchBorder": "{{ yellow }}",
        "editor.findMatchHighlightBackground": "{{ yellow }}25",
        "editor.findMatchHighlightBorder": "{{ yellow }}60",
        "editor.findRangeHighlightBackground": "{{ accent }}15",
        "editor.findRangeHighlightBorder": "{{ accent }}30",
        "searchEditor.findMatchBackground": "{{ yellow }}40",
        "searchEditor.findMatchBorder": "{{ yellow }}",
        "editor.hoverHighlightBackground": "{{ accent }}20",
        "editor.lineHighlightBackground": "{{ background }}60",
        "editor.lineHighlightBorder": "{{ background }}00",
        "editorLink.activeForeground": "{{ blue }}",
        "editor.rangeHighlightBackground": "{{ accent }}10",
        "editor.rangeHighlightBorder": "{{ accent }}20",
        "editor.symbolHighlightBackground": "{{ accent }}20",
        "editor.symbolHighlightBorder": "{{ accent }}40",
        "editorWhitespace.foreground": "{{ muted }}60",
        "editorIndentGuide.background1": "{{ muted }}30",
        "editorIndentGuide.background2": "{{ muted }}30",
        "editorIndentGuide.background3": "{{ muted }}30",
        "editorIndentGuide.background4": "{{ muted }}30",
        "editorIndentGuide.background5": "{{ muted }}30",
        "editorIndentGuide.background6": "{{ muted }}30",
        "editorIndentGuide.activeBackground1": "{{ muted }}80",
        "editorIndentGuide.activeBackground2": "{{ muted }}80",
        "editorIndentGuide.activeBackground3": "{{ muted }}80",
        "editorIndentGuide.activeBackground4": "{{ muted }}80",
        "editorIndentGuide.activeBackground5": "{{ muted }}80",
        "editorIndentGuide.activeBackground6": "{{ muted }}80",
        "editorInlayHint.background": "{{ muted }}30",
        "editorInlayHint.foreground": "{{ muted }}",
        "editorInlayHint.typeBackground": "{{ yellow }}15",
        "editorInlayHint.typeForeground": "{{ yellow }}",
        "editorInlayHint.parameterBackground": "{{ bright_magenta }}15",
        "editorInlayHint.parameterForeground": "{{ bright_magenta }}",
        "editorRuler.foreground": "{{ muted }}40",
        "editorCodeLens.foreground": "{{ muted }}",
        "editorLightBulb.foreground": "{{ yellow }}",
        "editorLightBulbAutoFix.foreground": "{{ green }}",
        "editorLightBulbAi.foreground": "{{ magenta }}",
        "editorBracketMatch.background": "{{ accent }}30",
        "editorBracketMatch.border": "{{ accent }}",
        "editorBracketHighlight.foreground1": "{{ blue }}",
        "editorBracketHighlight.foreground2": "{{ yellow }}",
        "editorBracketHighlight.foreground3": "{{ green }}",
        "editorBracketHighlight.foreground4": "{{ cyan }}",
        "editorBracketHighlight.foreground5": "{{ magenta }}",
        "editorBracketHighlight.foreground6": "{{ orange }}",
        "editorBracketHighlight.unexpectedBracket.foreground": "{{ red }}",
        "editorBracketPairGuide.activeBackground1": "{{ blue }}60",
        "editorBracketPairGuide.activeBackground2": "{{ yellow }}60",
        "editorBracketPairGuide.activeBackground3": "{{ green }}60",
        "editorBracketPairGuide.activeBackground4": "{{ cyan }}60",
        "editorBracketPairGuide.activeBackground5": "{{ magenta }}60",
        "editorBracketPairGuide.activeBackground6": "{{ orange }}60",
        "editorBracketPairGuide.background1": "{{ blue }}30",
        "editorBracketPairGuide.background2": "{{ yellow }}30",
        "editorBracketPairGuide.background3": "{{ green }}30",
        "editorBracketPairGuide.background4": "{{ cyan }}30",
        "editorBracketPairGuide.background5": "{{ magenta }}30",
        "editorBracketPairGuide.background6": "{{ orange }}30",
        "editorOverviewRuler.background": "{{ background }}",
        "editorOverviewRuler.border": "{{ muted }}20",
        "editorOverviewRuler.findMatchForeground": "{{ yellow }}80",
        "editorOverviewRuler.rangeHighlightForeground": "{{ accent }}60",
        "editorOverviewRuler.selectionHighlightForeground": "{{ accent }}80",
        "editorOverviewRuler.wordHighlightForeground": "{{ accent }}60",
        "editorOverviewRuler.wordHighlightStrongForeground": "{{ accent }}80",
        "editorOverviewRuler.wordHighlightTextForeground": "{{ accent }}40",
        "editorOverviewRuler.modifiedForeground": "{{ orange }}80",
        "editorOverviewRuler.addedForeground": "{{ green }}80",
        "editorOverviewRuler.deletedForeground": "{{ red }}80",
        "editorOverviewRuler.errorForeground": "{{ red }}",
        "editorOverviewRuler.warningForeground": "{{ yellow }}",
        "editorOverviewRuler.infoForeground": "{{ blue }}",
        "editorOverviewRuler.bracketMatchForeground": "{{ accent }}",
        "editorError.foreground": "{{ red }}",
        "editorError.background": "{{ red }}15",
        "editorError.border": "{{ red }}00",
        "editorWarning.foreground": "{{ yellow }}",
        "editorWarning.background": "{{ yellow }}15",
        "editorWarning.border": "{{ yellow }}00",
        "editorInfo.foreground": "{{ blue }}",
        "editorInfo.background": "{{ blue }}15",
        "editorInfo.border": "{{ blue }}00",
        "editorHint.foreground": "{{ cyan }}",
        "editorHint.border": "{{ cyan }}00",
        "problemsErrorIcon.foreground": "{{ red }}",
        "problemsWarningIcon.foreground": "{{ yellow }}",
        "problemsInfoIcon.foreground": "{{ blue }}",
        "editorUnnecessaryCode.opacity": "{{ background }}80",
        "editorUnnecessaryCode.border": "{{ muted }}",
        "editorGutter.background": "{{ background }}",
        "editorGutter.modifiedBackground": "{{ orange }}",
        "editorGutter.addedBackground": "{{ green }}",
        "editorGutter.deletedBackground": "{{ red }}",
        "editorGutter.commentRangeForeground": "{{ muted }}",
        "editorGutter.commentGlyphForeground": "{{ accent }}",
        "editorGutter.commentUnresolvedGlyphForeground": "{{ yellow }}",
        "editorGutter.foldingControlForeground": "{{ muted }}",
        "editorCommentsWidget.resolvedBorder": "{{ green }}",
        "editorCommentsWidget.unresolvedBorder": "{{ yellow }}",
        "editorCommentsWidget.rangeBackground": "{{ accent }}10",
        "editorCommentsWidget.rangeActiveBackground": "{{ accent }}20",

        "diffEditor.insertedTextBackground": "{{ green }}20",
        "diffEditor.insertedTextBorder": "{{ green }}00",
        "diffEditor.removedTextBackground": "{{ red }}20",
        "diffEditor.removedTextBorder": "{{ red }}00",
        "diffEditor.insertedLineBackground": "{{ green }}15",
        "diffEditor.removedLineBackground": "{{ red }}15",
        "diffEditorGutter.insertedLineBackground": "{{ green }}30",
        "diffEditorGutter.removedLineBackground": "{{ red }}30",
        "diffEditorOverview.insertedForeground": "{{ green }}80",
        "diffEditorOverview.removedForeground": "{{ red }}80",
        "diffEditor.diagonalFill": "{{ muted }}30",
        "diffEditor.unchangedRegionBackground": "{{ background }}",
        "diffEditor.unchangedRegionForeground": "{{ muted }}",
        "diffEditor.unchangedCodeBackground": "{{ background }}40",
        "diffEditor.move.border": "{{ cyan }}80",
        "diffEditor.moveActive.border": "{{ cyan }}",

        "editorWidget.foreground": "{{ foreground }}",
        "editorWidget.background": "{{ background }}",
        "editorWidget.border": "{{ muted }}",
        "editorWidget.resizeBorder": "{{ accent }}",
        "editorSuggestWidget.background": "{{ background }}",
        "editorSuggestWidget.border": "{{ muted }}",
        "editorSuggestWidget.foreground": "{{ foreground }}",
        "editorSuggestWidget.focusHighlightForeground": "{{ accent }}",
        "editorSuggestWidget.highlightForeground": "{{ accent }}",
        "editorSuggestWidget.selectedBackground": "{{ accent }}30",
        "editorSuggestWidget.selectedForeground": "{{ foreground }}",
        "editorSuggestWidget.selectedIconForeground": "{{ foreground }}",
        "editorSuggestWidgetStatus.foreground": "{{ muted }}",
        "editorHoverWidget.foreground": "{{ foreground }}",
        "editorHoverWidget.background": "{{ background }}",
        "editorHoverWidget.border": "{{ muted }}",
        "editorHoverWidget.highlightForeground": "{{ accent }}",
        "editorHoverWidget.statusBarBackground": "{{ muted }}30",
        "editorGhostText.foreground": "{{ muted }}",
        "editorGhostText.background": "{{ muted }}10",
        "editorGhostText.border": "{{ muted }}00",
        "editorStickyScroll.background": "{{ background }}",
        "editorStickyScrollHover.background": "{{ muted }}40",
        "debugExceptionWidget.background": "{{ red }}20",
        "debugExceptionWidget.border": "{{ red }}",
        "editorMarkerNavigation.background": "{{ background }}",
        "editorMarkerNavigationError.background": "{{ red }}20",
        "editorMarkerNavigationError.headerBackground": "{{ red }}15",
        "editorMarkerNavigationWarning.background": "{{ yellow }}20",
        "editorMarkerNavigationWarning.headerBackground": "{{ yellow }}15",
        "editorMarkerNavigationInfo.background": "{{ blue }}20",
        "editorMarkerNavigationInfo.headerBackground": "{{ blue }}15",

        "peekView.border": "{{ accent }}",
        "peekViewEditor.background": "{{ background }}",
        "peekViewEditorGutter.background": "{{ background }}",
        "peekViewEditor.matchHighlightBackground": "{{ yellow }}30",
        "peekViewEditor.matchHighlightBorder": "{{ yellow }}",
        "peekViewResult.background": "{{ background }}",
        "peekViewResult.fileForeground": "{{ foreground }}",
        "peekViewResult.lineForeground": "{{ muted }}",
        "peekViewResult.matchHighlightBackground": "{{ yellow }}30",
        "peekViewResult.selectionBackground": "{{ accent }}30",
        "peekViewResult.selectionForeground": "{{ foreground }}",
        "peekViewTitle.background": "{{ background }}",
        "peekViewTitleDescription.foreground": "{{ muted }}",
        "peekViewTitleLabel.foreground": "{{ foreground }}",

        "merge.currentContentBackground": "{{ cyan }}20",
        "merge.currentHeaderBackground": "{{ cyan }}40",
        "merge.incomingContentBackground": "{{ green }}20",
        "merge.incomingHeaderBackground": "{{ green }}40",
        "merge.commonContentBackground": "{{ muted }}20",
        "merge.commonHeaderBackground": "{{ muted }}40",
        "merge.border": "{{ muted }}",
        "editorOverviewRuler.currentContentForeground": "{{ cyan }}",
        "editorOverviewRuler.incomingContentForeground": "{{ green }}",
        "editorOverviewRuler.commonContentForeground": "{{ muted }}",
        "mergeEditor.change.background": "{{ accent }}15",
        "mergeEditor.change.word.background": "{{ accent }}30",
        "mergeEditor.conflict.handledUnfocused.border": "{{ green }}80",
        "mergeEditor.conflict.handled.minimapOverViewRuler": "{{ green }}",
        "mergeEditor.conflict.unhandledUnfocused.border": "{{ yellow }}80",
        "mergeEditor.conflict.unhandled.minimapOverViewRuler": "{{ yellow }}",
        "mergeEditor.conflictingLines.background": "{{ yellow }}15",
        "mergeEditor.changeBase.background": "{{ muted }}20",
        "mergeEditor.changeBase.word.background": "{{ muted }}40",

        "panel.background": "{{ background }}",
        "panel.border": "{{ muted }}40",
        "panel.dropBorder": "{{ accent }}",
        "panelTitle.activeBorder": "{{ accent }}",
        "panelTitle.activeForeground": "{{ foreground }}",
        "panelTitle.inactiveForeground": "{{ muted }}",
        "panelInput.border": "{{ muted }}",
        "panelSection.border": "{{ muted }}40",
        "panelSection.dropBackground": "{{ accent }}20",
        "panelSectionHeader.background": "{{ background }}",
        "panelSectionHeader.foreground": "{{ foreground }}",
        "panelSectionHeader.border": "{{ muted }}40",

        "outputView.background": "{{ background }}",
        "outputViewStickyScroll.background": "{{ background }}",

        "statusBar.background": "{{ background }}",
        "statusBar.foreground": "{{ foreground }}",
        "statusBar.border": "{{ background }}",
        "statusBar.debuggingBackground": "{{ yellow }}",
        "statusBar.debuggingForeground": "{{ background }}",
        "statusBar.debuggingBorder": "{{ yellow }}",
        "statusBar.noFolderBackground": "{{ background }}",
        "statusBar.noFolderForeground": "{{ foreground }}",
        "statusBar.noFolderBorder": "{{ background }}",
        "statusBar.focusBorder": "{{ accent }}",
        "statusBarItem.activeBackground": "{{ muted }}",
        "statusBarItem.hoverBackground": "{{ muted }}60",
        "statusBarItem.hoverForeground": "{{ foreground }}",
        "statusBarItem.prominentForeground": "{{ foreground }}",
        "statusBarItem.prominentBackground": "{{ accent }}",
        "statusBarItem.prominentHoverBackground": "{{ accent }}80",
        "statusBarItem.remoteBackground": "{{ accent }}",
        "statusBarItem.remoteForeground": "{{ background }}",
        "statusBarItem.remoteHoverBackground": "{{ accent }}80",
        "statusBarItem.errorBackground": "{{ red }}",
        "statusBarItem.errorForeground": "{{ background }}",
        "statusBarItem.errorHoverBackground": "{{ red }}80",
        "statusBarItem.warningBackground": "{{ yellow }}",
        "statusBarItem.warningForeground": "{{ background }}",
        "statusBarItem.warningHoverBackground": "{{ yellow }}80",
        "statusBarItem.compactHoverBackground": "{{ muted }}",
        "statusBarItem.focusBorder": "{{ accent }}",

        "titleBar.activeBackground": "{{ background }}",
        "titleBar.activeForeground": "{{ foreground }}",
        "titleBar.inactiveBackground": "{{ background }}",
        "titleBar.inactiveForeground": "{{ muted }}",
        "titleBar.border": "{{ background }}",

        "menubar.selectionForeground": "{{ foreground }}",
        "menubar.selectionBackground": "{{ accent }}30",
        "menubar.selectionBorder": "{{ accent }}00",
        "menu.foreground": "{{ foreground }}",
        "menu.background": "{{ background }}",
        "menu.selectionForeground": "{{ foreground }}",
        "menu.selectionBackground": "{{ accent }}30",
        "menu.selectionBorder": "{{ accent }}00",
        "menu.separatorBackground": "{{ muted }}",
        "menu.border": "{{ muted }}",

        "commandCenter.foreground": "{{ foreground }}",
        "commandCenter.activeForeground": "{{ foreground }}",
        "commandCenter.background": "{{ background }}",
        "commandCenter.activeBackground": "{{ muted }}",
        "commandCenter.border": "{{ muted }}",
        "commandCenter.inactiveForeground": "{{ muted }}",
        "commandCenter.inactiveBorder": "{{ muted }}",
        "commandCenter.activeBorder": "{{ accent }}",
        "commandCenter.debuggingBackground": "{{ yellow }}20",

        "notificationCenter.border": "{{ muted }}",
        "notificationCenterHeader.foreground": "{{ foreground }}",
        "notificationCenterHeader.background": "{{ background }}",
        "notificationToast.border": "{{ muted }}",
        "notifications.foreground": "{{ foreground }}",
        "notifications.background": "{{ background }}",
        "notifications.border": "{{ muted }}",
        "notificationLink.foreground": "{{ accent }}",
        "notificationsErrorIcon.foreground": "{{ red }}",
        "notificationsWarningIcon.foreground": "{{ yellow }}",
        "notificationsInfoIcon.foreground": "{{ blue }}",

        "banner.background": "{{ accent }}20",
        "banner.foreground": "{{ foreground }}",
        "banner.iconForeground": "{{ accent }}",

        "extensionButton.prominentBackground": "{{ accent }}",
        "extensionButton.prominentForeground": "{{ background }}",
        "extensionButton.prominentHoverBackground": "{{ accent }}80",
        "extensionButton.background": "{{ muted }}",
        "extensionButton.foreground": "{{ foreground }}",
        "extensionButton.hoverBackground": "{{ muted }}80",
        "extensionButton.separator": "{{ background }}",
        "extensionBadge.remoteBackground": "{{ accent }}",
        "extensionBadge.remoteForeground": "{{ background }}",
        "extensionIcon.starForeground": "{{ yellow }}",
        "extensionIcon.verifiedForeground": "{{ cyan }}",
        "extensionIcon.preReleaseForeground": "{{ yellow }}",
        "extensionIcon.sponsorForeground": "{{ magenta }}",

        "pickerGroup.border": "{{ muted }}",
        "pickerGroup.foreground": "{{ accent }}",
        "quickInput.background": "{{ background }}",
        "quickInput.foreground": "{{ foreground }}",
        "quickInputList.focusBackground": "{{ accent }}30",
        "quickInputList.focusForeground": "{{ foreground }}",
        "quickInputList.focusIconForeground": "{{ foreground }}",
        "quickInputTitle.background": "{{ background }}",

        "keybindingLabel.background": "{{ muted }}40",
        "keybindingLabel.foreground": "{{ foreground }}",
        "keybindingLabel.border": "{{ muted }}",
        "keybindingLabel.bottomBorder": "{{ muted }}",
        "keybindingTable.headerBackground": "{{ background }}",
        "keybindingTable.rowsBackground": "{{ background }}40",

        "terminal.background": "{{ background }}",
        "terminal.foreground": "{{ foreground }}",
        "terminal.border": "{{ muted }}40",
        "terminal.selectionBackground": "{{ selection_background }}60",
        "terminal.selectionForeground": "{{ selection_foreground }}",
        "terminal.inactiveSelectionBackground": "{{ selection_background }}30",
        "terminal.findMatchBackground": "{{ yellow }}40",
        "terminal.findMatchBorder": "{{ yellow }}",
        "terminal.findMatchHighlightBackground": "{{ yellow }}25",
        "terminal.findMatchHighlightBorder": "{{ yellow }}60",
        "terminal.hoverHighlightBackground": "{{ accent }}20",
        "terminalCursor.background": "{{ background }}",
        "terminalCursor.foreground": "{{ bright_foreground }}",
        "terminal.ansiBlack": "{{ background }}",
        "terminal.ansiRed": "{{ red }}",
        "terminal.ansiGreen": "{{ green }}",
        "terminal.ansiYellow": "{{ yellow }}",
        "terminal.ansiBlue": "{{ blue }}",
        "terminal.ansiMagenta": "{{ magenta }}",
        "terminal.ansiCyan": "{{ cyan }}",
        "terminal.ansiWhite": "{{ foreground }}",
        "terminal.ansiBrightBlack": "{{ muted }}",
        "terminal.ansiBrightRed": "{{ bright_red }}",
        "terminal.ansiBrightGreen": "{{ bright_green }}",
        "terminal.ansiBrightYellow": "{{ bright_yellow }}",
        "terminal.ansiBrightBlue": "{{ bright_blue }}",
        "terminal.ansiBrightMagenta": "{{ bright_magenta }}",
        "terminal.ansiBrightCyan": "{{ bright_cyan }}",
        "terminal.ansiBrightWhite": "{{ bright_foreground }}",
        "terminal.tab.activeBorder": "{{ accent }}",
        "terminalCommandDecoration.defaultBackground": "{{ muted }}",
        "terminalCommandDecoration.successBackground": "{{ green }}",
        "terminalCommandDecoration.errorBackground": "{{ red }}",
        "terminalOverviewRuler.cursorForeground": "{{ bright_foreground }}",
        "terminalOverviewRuler.findMatchForeground": "{{ yellow }}",
        "terminalStickyScroll.background": "{{ background }}",
        "terminalStickyScrollHover.background": "{{ muted }}40",

        "debugToolBar.background": "{{ background }}",
        "debugToolBar.border": "{{ muted }}",
        "debugView.stateLabelForeground": "{{ foreground }}",
        "debugView.stateLabelBackground": "{{ accent }}30",
        "debugView.valueChangedHighlight": "{{ cyan }}40",
        "debugView.exceptionLabelForeground": "{{ background }}",
        "debugView.exceptionLabelBackground": "{{ red }}",
        "debugTokenExpression.name": "{{ magenta }}",
        "debugTokenExpression.value": "{{ foreground }}",
        "debugTokenExpression.string": "{{ green }}",
        "debugTokenExpression.boolean": "{{ orange }}",
        "debugTokenExpression.number": "{{ orange }}",
        "debugTokenExpression.error": "{{ red }}",

        "testing.iconFailed": "{{ red }}",
        "testing.iconErrored": "{{ red }}",
        "testing.iconPassed": "{{ green }}",
        "testing.runAction": "{{ green }}",
        "testing.iconQueued": "{{ yellow }}",
        "testing.iconUnset": "{{ muted }}",
        "testing.iconSkipped": "{{ yellow }}",
        "testing.peekBorder": "{{ accent }}",
        "testing.peekHeaderBackground": "{{ background }}",
        "testing.message.error.decorationForeground": "{{ red }}",
        "testing.message.error.lineBackground": "{{ red }}15",
        "testing.message.info.decorationForeground": "{{ blue }}",
        "testing.message.info.lineBackground": "{{ blue }}15",

        "welcomePage.background": "{{ background }}",
        "welcomePage.tileBackground": "{{ background }}",
        "welcomePage.tileHoverBackground": "{{ muted }}40",
        "welcomePage.tileBorder": "{{ muted }}",
        "welcomePage.progress.background": "{{ muted }}",
        "welcomePage.progress.foreground": "{{ accent }}",
        "walkThrough.embeddedEditorBackground": "{{ background }}",
        "walkthrough.stepTitle.foreground": "{{ foreground }}",

        "gitDecoration.addedResourceForeground": "{{ green }}",
        "gitDecoration.modifiedResourceForeground": "{{ orange }}",
        "gitDecoration.deletedResourceForeground": "{{ red }}",
        "gitDecoration.renamedResourceForeground": "{{ cyan }}",
        "gitDecoration.stageModifiedResourceForeground": "{{ orange }}",
        "gitDecoration.stageDeletedResourceForeground": "{{ red }}",
        "gitDecoration.untrackedResourceForeground": "{{ green }}",
        "gitDecoration.ignoredResourceForeground": "{{ muted }}",
        "gitDecoration.conflictingResourceForeground": "{{ yellow }}",
        "gitDecoration.submoduleResourceForeground": "{{ magenta }}",

        "settings.headerForeground": "{{ foreground }}",
        "settings.modifiedItemIndicator": "{{ accent }}",
        "settings.dropdownBackground": "{{ background }}",
        "settings.dropdownForeground": "{{ foreground }}",
        "settings.dropdownBorder": "{{ muted }}",
        "settings.dropdownListBorder": "{{ muted }}",
        "settings.checkboxBackground": "{{ background }}",
        "settings.checkboxForeground": "{{ foreground }}",
        "settings.checkboxBorder": "{{ muted }}",
        "settings.rowHoverBackground": "{{ background }}",
        "settings.textInputBackground": "{{ background }}",
        "settings.textInputForeground": "{{ foreground }}",
        "settings.textInputBorder": "{{ muted }}",
        "settings.numberInputBackground": "{{ background }}",
        "settings.numberInputForeground": "{{ foreground }}",
        "settings.numberInputBorder": "{{ muted }}",
        "settings.focusedRowBackground": "{{ accent }}10",
        "settings.focusedRowBorder": "{{ accent }}40",
        "settings.headerBorder": "{{ muted }}",
        "settings.sashBorder": "{{ muted }}",
        "settings.settingsHeaderHoverForeground": "{{ accent }}",

        "breadcrumb.foreground": "{{ muted }}",
        "breadcrumb.background": "{{ background }}",
        "breadcrumb.focusForeground": "{{ foreground }}",
        "breadcrumb.activeSelectionForeground": "{{ foreground }}",
        "breadcrumbPicker.background": "{{ background }}",

        "editor.snippetTabstopHighlightBackground": "{{ accent }}20",
        "editor.snippetTabstopHighlightBorder": "{{ accent }}40",
        "editor.snippetFinalTabstopHighlightBackground": "{{ green }}20",
        "editor.snippetFinalTabstopHighlightBorder": "{{ green }}40",

        "symbolIcon.arrayForeground": "{{ orange }}",
        "symbolIcon.booleanForeground": "{{ orange }}",
        "symbolIcon.classForeground": "{{ yellow }}",
        "symbolIcon.colorForeground": "{{ cyan }}",
        "symbolIcon.constantForeground": "{{ bright_yellow }}",
        "symbolIcon.constructorForeground": "{{ blue }}",
        "symbolIcon.enumeratorForeground": "{{ yellow }}",
        "symbolIcon.enumeratorMemberForeground": "{{ orange }}",
        "symbolIcon.eventForeground": "{{ yellow }}",
        "symbolIcon.fieldForeground": "{{ foreground }}",
        "symbolIcon.fileForeground": "{{ foreground }}",
        "symbolIcon.folderForeground": "{{ foreground }}",
        "symbolIcon.functionForeground": "{{ blue }}",
        "symbolIcon.interfaceForeground": "{{ yellow }}",
        "symbolIcon.keyForeground": "{{ bright_magenta }}",
        "symbolIcon.keywordForeground": "{{ bright_magenta }}",
        "symbolIcon.methodForeground": "{{ blue }}",
        "symbolIcon.moduleForeground": "{{ yellow }}",
        "symbolIcon.namespaceForeground": "{{ blue }}",
        "symbolIcon.nullForeground": "{{ orange }}",
        "symbolIcon.numberForeground": "{{ orange }}",
        "symbolIcon.objectForeground": "{{ yellow }}",
        "symbolIcon.operatorForeground": "{{ bright_blue }}",
        "symbolIcon.packageForeground": "{{ yellow }}",
        "symbolIcon.propertyForeground": "{{ foreground }}",
        "symbolIcon.referenceForeground": "{{ bright_magenta }}",
        "symbolIcon.snippetForeground": "{{ green }}",
        "symbolIcon.stringForeground": "{{ green }}",
        "symbolIcon.structForeground": "{{ yellow }}",
        "symbolIcon.textForeground": "{{ foreground }}",
        "symbolIcon.typeParameterForeground": "{{ yellow }}",
        "symbolIcon.unitForeground": "{{ orange }}",
        "symbolIcon.variableForeground": "{{ bright_magenta }}",

        "debugIcon.breakpointForeground": "{{ red }}",
        "debugIcon.breakpointDisabledForeground": "{{ muted }}",
        "debugIcon.breakpointUnverifiedForeground": "{{ yellow }}",
        "debugIcon.breakpointCurrentStackframeForeground": "{{ yellow }}",
        "debugIcon.breakpointStackframeForeground": "{{ green }}",
        "debugIcon.startForeground": "{{ green }}",
        "debugIcon.pauseForeground": "{{ yellow }}",
        "debugIcon.stopForeground": "{{ red }}",
        "debugIcon.disconnectForeground": "{{ red }}",
        "debugIcon.restartForeground": "{{ green }}",
        "debugIcon.stepOverForeground": "{{ blue }}",
        "debugIcon.stepIntoForeground": "{{ cyan }}",
        "debugIcon.stepOutForeground": "{{ magenta }}",
        "debugIcon.continueForeground": "{{ green }}",
        "debugIcon.stepBackForeground": "{{ yellow }}",
        "debugConsole.infoForeground": "{{ blue }}",
        "debugConsole.warningForeground": "{{ yellow }}",
        "debugConsole.errorForeground": "{{ red }}",
        "debugConsole.sourceForeground": "{{ foreground }}",
        "debugConsoleInputIcon.foreground": "{{ accent }}",

        "notebook.editorBackground": "{{ background }}",
        "notebook.cellBorderColor": "{{ muted }}40",
        "notebook.cellHoverBackground": "{{ background }}40",
        "notebook.cellInsertionIndicator": "{{ accent }}",
        "notebook.cellStatusBarItemHoverBackground": "{{ muted }}",
        "notebook.cellToolbarSeparator": "{{ muted }}",
        "notebook.cellEditorBackground": "{{ background }}",
        "notebook.focusedCellBackground": "{{ background }}60",
        "notebook.focusedCellBorder": "{{ accent }}",
        "notebook.focusedEditorBorder": "{{ accent }}",
        "notebook.inactiveFocusedCellBorder": "{{ muted }}",
        "notebook.inactiveSelectedCellBorder": "{{ muted }}",
        "notebook.outputContainerBackgroundColor": "{{ background }}",
        "notebook.outputContainerBorderColor": "{{ muted }}40",
        "notebook.selectedCellBackground": "{{ accent }}15",
        "notebook.selectedCellBorder": "{{ accent }}40",
        "notebook.symbolHighlightBackground": "{{ accent }}20",
        "notebookStatusErrorIcon.foreground": "{{ red }}",
        "notebookStatusRunningIcon.foreground": "{{ accent }}",
        "notebookStatusSuccessIcon.foreground": "{{ green }}",
        "notebookEditorOverviewRuler.runningCellForeground": "{{ accent }}",

        "charts.foreground": "{{ foreground }}",
        "charts.lines": "{{ muted }}",
        "charts.red": "{{ red }}",
        "charts.blue": "{{ blue }}",
        "charts.yellow": "{{ yellow }}",
        "charts.orange": "{{ orange }}",
        "charts.green": "{{ green }}",
        "charts.purple": "{{ magenta }}",

        "ports.iconRunningProcessForeground": "{{ accent }}",

        "commentsView.resolvedIcon": "{{ green }}",
        "commentsView.unresolvedIcon": "{{ yellow }}",

        "editorWatermark.foreground": "{{ muted }}",

        "inlineChat.background": "{{ background }}",
        "inlineChat.border": "{{ muted }}",
        "inlineChat.shadow": "{{ background }}80",
        "inlineChatInput.border": "{{ muted }}",
        "inlineChatInput.focusBorder": "{{ accent }}",
        "inlineChatInput.placeholderForeground": "{{ muted }}",
        "inlineChatInput.background": "{{ background }}",
        "inlineChatDiff.inserted": "{{ green }}20",
        "inlineChatDiff.removed": "{{ red }}20",

        "chat.requestBackground": "{{ background }}",
        "chat.requestBorder": "{{ muted }}"
    },
    "tokenColors": [
    {
        "name": "Comments",
        "scope": [
            "comment",
            "punctuation.definition.comment",
            "comment.line",
            "comment.block"
        ],
        "settings": {
            "fontStyle": "italic",
            "foreground": "{{ muted }}"
        }
    },
    {
        "name": "Docstrings and Documentation",
        "scope": [
            "string.quoted.docstring",
            "string.quoted.docstring.multi",
            "string.quoted.multi.python",
            "comment.block.documentation"
        ],
        "settings": {
            "fontStyle": "italic",
            "foreground": "{{ muted }}"
        }
    },
    {
        "name": "Keywords - General & Storage",
        "scope": [
            "keyword",
            "storage.type",
            "storage.type.class",
            "storage.type.function",
            "storage.type.enum",
            "storage.type.interface",
            "storage.type.struct",
            "storage.modifier",
            "keyword.declaration"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Keywords - Control Flow",
        "scope": [
            "keyword.control",
            "keyword.control.flow",
            "keyword.control.conditional",
            "keyword.control.loop",
            "keyword.control.exception",
            "keyword.control.return",
            "keyword.control.trycatch",
            "keyword.control.async",
            "keyword.control.yield"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Keywords - Import / Module",
        "scope": [
            "keyword.control.import",
            "keyword.control.export",
            "keyword.control.from",
            "keyword.control.as",
            "keyword.control.default",
            "keyword.other.import"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Logical Word Operators",
        "scope": [
            "keyword.operator.logical.python",
            "keyword.operator.word"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Operators",
        "scope": [
            "keyword.operator",
            "keyword.operator.assignment",
            "keyword.operator.arithmetic",
            "keyword.operator.comparison",
            "keyword.operator.bitwise",
            "keyword.operator.logical",
            "keyword.operator.ternary",
            "keyword.operator.increment-decrement",
            "keyword.operator.expression",
            "keyword.operator.new"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "Type Annotation Arrows and Delimiters",
        "scope": [
            "punctuation.separator.arrow",
            "punctuation.definition.arrow",
            "keyword.operator.spread",
            "keyword.operator.rest"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "Types & Classes",
        "scope": [
            "entity.name.type",
            "entity.name.type.class",
            "support.class",
            "entity.other.inherited-class",
            "entity.name.type.struct",
            "entity.name.type.interface",
            "entity.name.type.enum"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Primitive & Built-in Types",
        "scope": [
            "support.type.primitive",
            "support.type",
            "storage.type.primitive",
            "storage.type.built-in",
            "storage.type.annotation"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}"
        }
    },
    {
        "name": "Type Parameters / Generics",
        "scope": [
            "entity.name.type.parameter",
            "variable.type.parameter"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "Namespaces & Modules",
        "scope": [
            "entity.name.namespace",
            "entity.name.type.module"
        ],
        "settings": {
            "foreground": "{{ bright_blue }}"
        }
    },
    {
        "name": "Function & Method Declarations",
        "scope": [
            "entity.name.function",
            "entity.name.function.method",
            "meta.function.declaration entity.name.function",
            "meta.method.declaration entity.name.function"
        ],
        "settings": {
            "foreground": "{{ cyan }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Function & Method Calls",
        "scope": [
            "meta.function-call.generic",
            "meta.function-call entity.name.function",
            "meta.method-call entity.name.function"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "Builtin & Magic Functions",
        "scope": [
            "support.function",
            "support.function.builtin",
            "support.function.magic.python",
            "support.function.core",
            "support.function.console"
        ],
        "settings": {
            "foreground": "{{ bright_cyan }}"
        }
    },
    {
        "name": "Decorators & Annotations",
        "scope": [
            "entity.name.function.decorator",
            "meta.decorator",
            "punctuation.decorator",
            "meta.annotation"
        ],
        "settings": {
            "foreground": "{{ magenta }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "Receiver Variables (self, cls, this)",
        "scope": [
            "variable.language.self",
            "variable.language.this",
            "variable.language.special.self",
            "variable.parameter.function.language.special.self",
            "variable.parameter.function.language.special.self.python",
            "variable.language.cls",
            "variable.language.special.cls",
            "variable.parameter.function.language.special.cls",
            "variable.parameter.function.language.special.cls.python"
        ],
        "settings": {
            "foreground": "{{ red }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "Language Builtin Variables",
        "scope": [
            "variable.language.super",
            "variable.language"
        ],
        "settings": {
            "foreground": "{{ bright_cyan }}"
        }
    },
    {
        "name": "Parameters & Keyword Arguments",
        "scope": [
            "variable.parameter",
            "entity.name.variable.parameter",
            "meta.function.parameter",
            "variable.parameter.function",
            "meta.parameter"
        ],
        "settings": {
            "foreground": "{{ orange }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "Properties & Object Attributes",
        "scope": [
            "variable.other.property",
            "variable.other.object.property",
            "meta.property-name",
            "variable.other.member"
        ],
        "settings": {
            "foreground": "{{ bright_blue }}"
        }
    },
    {
        "name": "Constants & Enums",
        "scope": [
            "variable.other.constant",
            "constant.other",
            "variable.other.enummember"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}"
        }
    },
    {
        "name": "Variables & Identifiers",
        "scope": [
            "variable",
            "variable.other",
            "variable.other.readwrite"
        ],
        "settings": {
            "foreground": "{{ foreground }}"
        }
    },
    {
        "name": "Numeric Constants",
        "scope": [
            "constant.numeric",
            "constant.numeric.integer",
            "constant.numeric.float",
            "constant.numeric.hex",
            "constant.numeric.octal",
            "constant.numeric.binary",
            "constant.numeric.complex"
        ],
        "settings": {
            "foreground": "{{ orange }}"
        }
    },
    {
        "name": "Boolean and Null Constants",
        "scope": [
            "constant.language.boolean",
            "constant.language.null",
            "constant.language.undefined",
            "constant.language.python"
        ],
        "settings": {
            "foreground": "{{ orange }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Strings",
        "scope": [
            "string",
            "string.quoted",
            "string.quoted.single",
            "string.quoted.double"
        ],
        "settings": {
            "foreground": "{{ bright_green }}"
        }
    },
    {
        "name": "String Quotes & Delimiters",
        "scope": [
            "punctuation.definition.string.begin",
            "punctuation.definition.string.end"
        ],
        "settings": {
            "foreground": "{{ bright_green }}"
        }
    },
    {
        "name": "Character Escape Sequences",
        "scope": [
            "constant.character.escape",
            "constant.character.escape.regexp"
        ],
        "settings": {
            "foreground": "{{ magenta }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Python String Format Modifiers and Specifiers",
        "scope": [
            "storage.type.format.python",
            "storage.type.string.python",
            "constant.character.format.placeholder.other.python",
            "meta.format.specifier.python"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Template Expression Braces & Interpolation",
        "scope": [
            "punctuation.definition.template-expression.begin",
            "punctuation.definition.template-expression.end",
            "punctuation.section.embedded.begin",
            "punctuation.section.embedded.end"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "Embedded Expression Body",
        "scope": [
            "meta.embedded",
            "meta.embedded.line",
            "meta.template.expression variable",
            "source.python meta.embedded.line.python"
        ],
        "settings": {
            "foreground": "{{ foreground }}"
        }
    },
    {
        "name": "Regular Expressions",
        "scope": [
            "string.regexp",
            "constant.other.character-class.regexp"
        ],
        "settings": {
            "foreground": "{{ bright_cyan }}"
        }
    },
    {
        "name": "Punctuation & Delimiters",
        "scope": [
            "punctuation",
            "meta.brace",
            "meta.bracket",
            "punctuation.definition.parameters",
            "punctuation.definition.arguments",
            "punctuation.separator.comma",
            "punctuation.terminator",
            "punctuation.separator.colon",
            "punctuation.separator.key-value"
        ],
        "settings": {
            "foreground": "{{ dark_foreground }}"
        }
    },
    {
        "name": "Punctuation Accessors (dots)",
        "scope": [
            "punctuation.accessor",
            "punctuation.separator.period"
        ],
        "settings": {
            "foreground": "{{ dark_foreground }}"
        }
    },
    {
        "name": "HTML & JSX Tags",
        "scope": [
            "entity.name.tag",
            "punctuation.definition.tag"
        ],
        "settings": {
            "foreground": "{{ magenta }}"
        }
    },
    {
        "name": "HTML & JSX Attributes",
        "scope": [
            "entity.other.attribute-name",
            "entity.other.attribute-name.jsx"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "CSS Selectors",
        "scope": [
            "entity.other.attribute-name.class.css",
            "entity.other.attribute-name.id.css"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}"
        }
    },
    {
        "name": "CSS Property Names",
        "scope": [
            "support.type.property-name.css",
            "support.type.vendored.property-name.css",
            "meta.property-name.css"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "CSS Values & Units",
        "scope": [
            "support.constant.property-value.css",
            "meta.property-value.css"
        ],
        "settings": {
            "foreground": "{{ foreground }}"
        }
    },
    {
        "name": "CSS Units",
        "scope": [
            "keyword.other.unit.css"
        ],
        "settings": {
            "foreground": "{{ orange }}"
        }
    },
    {
        "name": "JSON Keys",
        "scope": [
            "source.json meta.structure.dictionary.json support.type.property-name.json"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}"
        }
    },
    {
        "name": "Markdown Headings",
        "scope": [
            "markup.heading",
            "entity.name.section.markdown",
            "punctuation.definition.heading.markdown"
        ],
        "settings": {
            "foreground": "{{ bright_yellow }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Markdown Bold",
        "scope": [
            "markup.bold",
            "punctuation.definition.bold.markdown"
        ],
        "settings": {
            "foreground": "{{ bright_foreground }}",
            "fontStyle": "bold"
        }
    },
    {
        "name": "Markdown Italic",
        "scope": [
            "markup.italic",
            "punctuation.definition.italic.markdown"
        ],
        "settings": {
            "foreground": "{{ foreground }}",
            "fontStyle": "italic"
        }
    },
    {
        "name": "Markdown Code",
        "scope": [
            "markup.inline.raw",
            "markup.fenced_code.block",
            "markup.raw.block"
        ],
        "settings": {
            "foreground": "{{ bright_green }}"
        }
    },
    {
        "name": "Markdown Links",
        "scope": [
            "markup.underline.link",
            "string.other.link.title.markdown"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "Markdown Lists",
        "scope": [
            "punctuation.definition.list.begin.markdown"
        ],
        "settings": {
            "foreground": "{{ cyan }}"
        }
    },
    {
        "name": "Diff Inserted",
        "scope": [
            "markup.inserted",
            "punctuation.definition.inserted"
        ],
        "settings": {
            "foreground": "{{ bright_green }}"
        }
    },
    {
        "name": "Diff Deleted",
        "scope": [
            "markup.deleted",
            "punctuation.definition.deleted"
        ],
        "settings": {
            "foreground": "{{ red }}"
        }
    },
    {
        "name": "Diff Changed",
        "scope": [
            "markup.changed",
            "punctuation.definition.changed"
        ],
        "settings": {
            "foreground": "{{ orange }}"
        }
    },
    {
        "name": "Invalid / Deprecated",
        "scope": [
            "invalid",
            "invalid.illegal"
        ],
        "settings": {
            "foreground": "{{ red }}",
            "fontStyle": "strikethrough"
        }
    }
]
}
