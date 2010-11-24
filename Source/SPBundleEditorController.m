//
//  $Id$
//
//  SPBundleEditorController.m
//  sequel-pro
//
//  Created by Hans-Jörg Bibiko on November 12, 2010
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//  More info at <http://code.google.com/p/sequel-pro/>

#import "SPBundleEditorController.h"
#import "SPArrayAdditions.h"


@interface SPBundleEditorController (PrivateAPI)

- (void)_updateInputPopupButton;

@end

#pragma mark -

@implementation SPBundleEditorController

/**
 * Initialisation
 */
- (id)init
{

	if ((self = [super initWithWindowNibName:@"BundleEditor"])) {
		commandBundleArray = nil;
		draggedFilePath = nil;
		oldBundleName = nil;
		isTableCellEditing = NO;
		bundlePath = [[[NSFileManager defaultManager] applicationSupportDirectoryForSubDirectory:SPBundleSupportFolder createIfNotExists:NO error:nil] retain];
	}
	
	return self;

}

- (void)dealloc
{

	[inputGeneralScopePopUpMenu release];
	[inputInputFieldScopePopUpMenu release];
	[inputDataTableScopePopUpMenu release];
	[outputGeneralScopePopUpMenu release];
	[outputInputFieldScopePopUpMenu release];
	[outputDataTableScopePopUpMenu release];
	[inputFallbackInputFieldScopePopUpMenu release];
	[inputNonePopUpMenu release];

	[inputGeneralScopeArray release];
	[inputInputFieldScopeArray release];
	[inputDataTableScopeArray release];
	[outputGeneralScopeArray release];
	[outputInputFieldScopeArray release];
	[outputDataTableScopeArray release];
	[inputFallbackInputFieldScopeArray release];

	if(commandBundleArray) [commandBundleArray release], commandBundleArray = nil;
	if(commandBundleTree) [commandBundleTree release], commandBundleTree = nil;
	if(bundlePath) [bundlePath release], bundlePath = nil;

	[super dealloc];

}

- (void)awakeFromNib
{

	commandBundleArray = [[NSMutableArray alloc] initWithCapacity:1];
	commandBundleTree = [[NSMutableDictionary alloc] initWithCapacity:1];

	[commandBundleTree setObject:[NSMutableArray array] forKey:@"children"];
	[commandBundleTree setObject:@"Bundles" forKey:@"bundleName"];
	[[commandBundleTree objectForKey:@"children"] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"children", NSLocalizedString(@"Input Field", @"input field scope menu label"), @"bundleName", nil]];
	[[commandBundleTree objectForKey:@"children"] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"children", NSLocalizedString(@"Data Table", @"data table scope menu label"), @"bundleName", nil]];
	[[commandBundleTree objectForKey:@"children"] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"children", NSLocalizedString(@"General", @"general scope menu label"), @"bundleName", nil]];

	// Init all needed menus
	inputGeneralScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	inputInputFieldScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	inputDataTableScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	inputNonePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	outputGeneralScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	outputInputFieldScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	outputDataTableScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];
	inputFallbackInputFieldScopePopUpMenu = [[NSMenu alloc] initWithTitle:@""];

	inputGeneralScopeArray = [[NSArray arrayWithObjects:SPBundleInputSourceNone, nil] retain];
	inputInputFieldScopeArray = [[NSArray arrayWithObjects:SPBundleInputSourceNone, SPBundleInputSourceSelectedText, SPBundleInputSourceEntireContent, nil] retain];
	inputDataTableScopeArray = [[NSArray arrayWithObjects:SPBundleInputSourceNone, SPBundleInputSourceSelectedTableRowsAsTab, SPBundleInputSourceSelectedTableRowsAsCsv, SPBundleInputSourceSelectedTableRowsAsSqlInsert, SPBundleInputSourceTableRowsAsTab, SPBundleInputSourceTableRowsAsCsv, SPBundleInputSourceTableRowsAsSqlInsert, nil] retain];
	outputInputFieldScopeArray = [[NSArray arrayWithObjects:SPBundleOutputActionNone, SPBundleOutputActionInsertAsText, SPBundleOutputActionInsertAsSnippet, SPBundleOutputActionReplaceSelection, SPBundleOutputActionReplaceContent, SPBundleOutputActionShowAsTextTooltip, SPBundleOutputActionShowAsHTMLTooltip, SPBundleOutputActionShowAsHTML, nil] retain];
	outputGeneralScopeArray = [[NSArray arrayWithObjects:SPBundleOutputActionNone, SPBundleOutputActionShowAsTextTooltip, SPBundleOutputActionShowAsHTMLTooltip, SPBundleOutputActionShowAsHTML, nil] retain];
	outputDataTableScopeArray = [[NSArray arrayWithObjects:SPBundleOutputActionNone, SPBundleOutputActionShowAsTextTooltip, SPBundleOutputActionShowAsHTMLTooltip, SPBundleOutputActionShowAsHTML, nil] retain];
	inputFallbackInputFieldScopeArray = [[NSArray arrayWithObjects:SPBundleInputSourceNone, SPBundleInputSourceCurrentWord, SPBundleInputSourceCurrentLine, SPBundleInputSourceCurrentQuery, SPBundleInputSourceEntireContent, nil] retain];

	NSMutableArray *allPopupScopeItems = [NSMutableArray array];
	[allPopupScopeItems addObjectsFromArray:inputGeneralScopeArray];
	[allPopupScopeItems addObjectsFromArray:inputInputFieldScopeArray];
	[allPopupScopeItems addObjectsFromArray:inputDataTableScopeArray];
	[allPopupScopeItems addObjectsFromArray:outputInputFieldScopeArray];
	[allPopupScopeItems addObjectsFromArray:outputGeneralScopeArray];
	[allPopupScopeItems addObjectsFromArray:outputDataTableScopeArray];
	[allPopupScopeItems addObjectsFromArray:inputFallbackInputFieldScopeArray];

	NSDictionary *menuItemTitles = [NSDictionary dictionaryWithObjects:
						[NSArray arrayWithObjects:
							NSLocalizedString(@"None", @"none menu item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Selected Text", @"selected text menu item label"),
							NSLocalizedString(@"Entire Content", @"entire content menu item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Selected Rows (TSV)", @"selected rows (TSV) menu item label"),
							NSLocalizedString(@"Selected Rows (CSV)", @"selected rows (CSV) menu item label"),
							NSLocalizedString(@"Selected Rows (SQL)", @"selected rows (SQL) menu item label"),
							NSLocalizedString(@"Table Content (TSV)", @"table content (TSV) menu item label"),
							NSLocalizedString(@"Table Content (CSV)", @"table content (CSV) menu item label"),
							NSLocalizedString(@"Table Content (SQL)", @"table content (SQL) menu item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Insert as Text", @"insert as text item label"),
							NSLocalizedString(@"Insert as Snippet", @"insert as snippet item label"),
							NSLocalizedString(@"Replace Selection", @"replace selection item label"),
							NSLocalizedString(@"Replace Entire Content", @"replace entire content item label"),
							NSLocalizedString(@"Show as Text Tooltip", @"show as text tooltip item label"),
							NSLocalizedString(@"Show as HTML Tooltip", @"show as html tooltip item label"),
							NSLocalizedString(@"Show as HTML", @"show as html item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Show as Text Tooltip", @"show as text tooltip item label"),
							NSLocalizedString(@"Show as HTML Tooltip", @"show as html tooltip item label"),
							NSLocalizedString(@"Show as HTML", @"show as html item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Show as Text Tooltip", @"show as text tooltip item label"),
							NSLocalizedString(@"Show as HTML Tooltip", @"show as html tooltip item label"),
							NSLocalizedString(@"Show as HTML", @"show as html item label"),

							NSLocalizedString(@"None", @"none menu item label"),
							NSLocalizedString(@"Current Word", @"current word item label"),
							NSLocalizedString(@"Current Line", @"current line item label"),
							NSLocalizedString(@"Current Query", @"current query item label"),
							NSLocalizedString(@"Entire Content", @"entire content item label"),
						nil]
					forKeys:allPopupScopeItems];

	NSMenuItem *anItem;
	for(NSString* title in inputGeneralScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(inputPopupButtonChanged:) keyEquivalent:@""];
		[inputGeneralScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in inputInputFieldScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(inputPopupButtonChanged:) keyEquivalent:@""];
		[inputInputFieldScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in inputDataTableScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(inputPopupButtonChanged:) keyEquivalent:@""];
		[inputDataTableScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in outputGeneralScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(outputPopupButtonChanged:) keyEquivalent:@""];
		[outputGeneralScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in outputInputFieldScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(outputPopupButtonChanged:) keyEquivalent:@""];
		[outputInputFieldScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in outputDataTableScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(outputPopupButtonChanged:) keyEquivalent:@""];
		[outputDataTableScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	for(NSString* title in inputFallbackInputFieldScopeArray) {
		anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:title] action:@selector(inputFallbackPopupButtonChanged:) keyEquivalent:@""];
		[inputFallbackInputFieldScopePopUpMenu addItem:anItem];
		[anItem release];
	}
	anItem = [[NSMenuItem alloc] initWithTitle:[menuItemTitles objectForKey:SPBundleInputSourceNone] action:nil keyEquivalent:@""];
	[inputNonePopUpMenu addItem:anItem];
	[anItem release];

	[inputGeneralScopePopUpMenu removeAllItems];
	anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"General", @"general scope menu label") action:@selector(scopeButtonChanged:) keyEquivalent:@""];
	[anItem setTag:0];
	[inputGeneralScopePopUpMenu addItem:anItem];
	[anItem release];
	anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Input Field", @"input field scope menu label") action:@selector(scopeButtonChanged:) keyEquivalent:@""];
	[anItem setTag:1];
	[inputGeneralScopePopUpMenu addItem:anItem];
	[anItem release];
	anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Data Table", @"data table scope menu label") action:@selector(scopeButtonChanged:) keyEquivalent:@""];
	[anItem setTag:2];
	[inputGeneralScopePopUpMenu addItem:anItem];
	[anItem release];
	[inputGeneralScopePopUpMenu addItem:[NSMenuItem separatorItem]];
	anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Disable Command", @"disable command menu label") action:@selector(scopeButtonChanged:) keyEquivalent:@""];
	[anItem setTag:10];
	[inputGeneralScopePopUpMenu addItem:anItem];
	[anItem release];
	[scopePopupButton setMenu:inputGeneralScopePopUpMenu];

	[keyEquivalentField setCanCaptureGlobalHotKeys:YES];

}

#pragma mark -

- (IBAction)inputPopupButtonChanged:(id)sender
{

	id currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];

	NSMenu* senderMenu = [sender menu];

	NSInteger selectedIndex = [senderMenu indexOfItem:sender];
	NSString *input = SPBundleInputSourceNone;
	if(senderMenu == inputGeneralScopePopUpMenu)
		input = [inputGeneralScopeArray objectAtIndex:selectedIndex];
	else if(senderMenu == inputInputFieldScopePopUpMenu)
		input = [inputInputFieldScopeArray objectAtIndex:selectedIndex];
	else if(senderMenu == inputDataTableScopePopUpMenu)
		input = [inputDataTableScopeArray objectAtIndex:selectedIndex];
	else if(senderMenu == inputNonePopUpMenu)
		input = SPBundleInputSourceNone;

	[currentDict setObject:input forKey:SPBundleFileInputSourceKey];

	[self _updateInputPopupButton];

}

- (IBAction)inputFallbackPopupButtonChanged:(id)sender
{

	id currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];

	NSMenu* senderMenu = [sender menu];

	NSInteger selectedIndex = [senderMenu indexOfItem:sender];
	NSString *input = SPBundleInputSourceNone;
	if(senderMenu == inputFallbackInputFieldScopePopUpMenu)
		input = [inputFallbackInputFieldScopeArray objectAtIndex:selectedIndex];

	[currentDict setObject:input forKey:SPBundleFileInputSourceFallBackKey];

}

- (IBAction)outputPopupButtonChanged:(id)sender
{

	id currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];

	NSMenu* senderMenu = [sender menu];

	NSInteger selectedIndex = [senderMenu indexOfItem:sender];
	NSString *output = SPBundleOutputActionNone;
	if(senderMenu == outputGeneralScopePopUpMenu)
		output = [outputGeneralScopeArray objectAtIndex:selectedIndex];
	else if(senderMenu == outputInputFieldScopePopUpMenu)
		output = [outputInputFieldScopeArray objectAtIndex:selectedIndex];
	else if(senderMenu == outputDataTableScopePopUpMenu)
		output = [outputDataTableScopeArray objectAtIndex:selectedIndex];

	[currentDict setObject:output forKey:SPBundleFileOutputActionKey];

}

- (IBAction)scopeButtonChanged:(id)sender
{

	id currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];

	NSInteger selectedTag = [sender tag];

	switch(selectedTag) {
		case 0:
		[currentDict setObject:SPBundleScopeGeneral forKey:SPBundleFileScopeKey];
		break;
		case 1:
		[currentDict setObject:SPBundleScopeInputField forKey:SPBundleFileScopeKey];
		break;
		case 2:
		[currentDict setObject:SPBundleScopeDataTable forKey:SPBundleFileScopeKey];
		break;
		default:
		[currentDict setObject:@"" forKey:SPBundleFileScopeKey];
	}

	[self _updateInputPopupButton];

}

- (IBAction)duplicateCommandBundle:(id)sender
{
	if ([commandsOutlineView numberOfSelectedRows] == 1)
		[self addCommandBundle:self];
	else
		NSBeep();
}

- (IBAction)addCommandBundle:(id)sender
{
	NSMutableDictionary *bundle;
	NSUInteger insertIndex;

	// Store pending changes in Query
	[[self window] makeFirstResponder:nameTextField];

	// Duplicate a selected Bundle if sender == self
	if (sender == self) {
		NSDictionary *currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];
		bundle = [NSMutableDictionary dictionaryWithDictionary:currentDict];

		NSString *bundleFileName = [bundle objectForKey:@"bundleName"];
		NSString *newFileName = [NSString stringWithFormat:@"%@_Copy", [bundle objectForKey:@"bundleName"]];
		NSString *possibleExisitingBundleFilePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, bundleFileName, SPUserBundleFileExtension];
		NSString *newBundleFilePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, newFileName, SPUserBundleFileExtension];

		BOOL isDir;
		BOOL copyingWasSuccessful = YES;
		// Copy possible existing bundle with content
		if([[NSFileManager defaultManager] fileExistsAtPath:possibleExisitingBundleFilePath isDirectory:&isDir] && isDir) {
			if(![[NSFileManager defaultManager] copyItemAtPath:possibleExisitingBundleFilePath toPath:newBundleFilePath error:nil])
				copyingWasSuccessful = NO;
		}
		if(!copyingWasSuccessful) {
			// try again with new name
			newFileName = [NSString stringWithFormat:@"%@_%ld", newFileName, (NSUInteger)(random() % 35000)];
			newBundleFilePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, newFileName, SPUserBundleFileExtension];
			if([[NSFileManager defaultManager] fileExistsAtPath:possibleExisitingBundleFilePath isDirectory:&isDir] && isDir) {
				if([[NSFileManager defaultManager] copyItemAtPath:possibleExisitingBundleFilePath toPath:newBundleFilePath error:nil])
					copyingWasSuccessful = YES;
			}
		}
		if(!copyingWasSuccessful) {

			[commandsOutlineView reloadData];

			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error", @"error")
											 defaultButton:NSLocalizedString(@"OK", @"OK button") 
										   alternateButton:nil 
											  otherButton:nil 
								informativeTextWithFormat:NSLocalizedString(@"Error while duplicating Bundle content.", @"error while duplicating Bundle content")];
		
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert runModal];

			return;

		}
		[bundle setObject:newFileName forKey:@"bundleName"];

	}
	// Add a new Bundle
	else {
		bundle = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"New Bundle", @"New Name", @"", SPBundleScopeGeneral, nil] 
						forKeys:[NSArray arrayWithObjects:@"bundleName", SPBundleFileNameKey, SPBundleFileCommandKey, SPBundleFileScopeKey, nil]];
	}
	if ([commandsOutlineView numberOfSelectedRows] > 0) {
		insertIndex = [[commandsOutlineView selectedRowIndexes] lastIndex]+1;
		[commandBundleArray insertObject:bundle atIndex:insertIndex];
	} 
	else {
		[commandBundleArray addObject:bundle];
		insertIndex = [commandBundleArray count] - 1;
	}

	[commandBundleTreeController rearrangeObjects];
	[commandsOutlineView reloadData];

	[commandsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertIndex] byExtendingSelection:NO];
	
	[commandsOutlineView scrollRowToVisible:[commandsOutlineView selectedRow]];

	[removeButton setEnabled:([[commandBundleTreeController selectedObjects] count] > 0)];

	[self _updateInputPopupButton];

	[[self window] makeFirstResponder:commandsOutlineView];

}

- (IBAction)removeCommandBundle:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Remove selected Bundles?", @"remove selected bundles message") 
									 defaultButton:NSLocalizedString(@"Remove", @"remove button")
								   alternateButton:NSLocalizedString(@"Cancel", @"cancel button")
									   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"Are you sure you want to move all selected Bundles to the Trash and remove them respectively?", @"move to trash and remove resp all selected bundles informative message")];

	[alert setAlertStyle:NSCriticalAlertStyle];
	
	NSArray *buttons = [alert buttons];
	
	// Change the alert's cancel button to have the key equivalent of return
	[[buttons objectAtIndex:0] setKeyEquivalent:@"r"];
	[[buttons objectAtIndex:0] setKeyEquivalentModifierMask:NSCommandKeyMask];
	[[buttons objectAtIndex:1] setKeyEquivalent:@"\r"];
	
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:@"removeSelectedBundles"];

}

- (IBAction)revealCommandBundleInFinder:(id)sender
{

	if([commandsOutlineView numberOfSelectedRows] != 1) return;

	[[NSWorkspace sharedWorkspace] selectFile:[NSString stringWithFormat:@"%@/%@.%@/%@", 
		bundlePath, [[[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject] objectForKey:@"bundleName"], SPUserBundleFileExtension, SPBundleFileName] inFileViewerRootedAtPath:nil];

}

- (IBAction)saveBundle:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setRequiredFileType:SPUserBundleFileExtension];
	
	[panel setExtensionHidden:NO];
	[panel setAllowsOtherFileTypes:NO];
	[panel setCanSelectHiddenExtension:YES];
	[panel setCanCreateDirectories:YES];

	[panel beginSheetForDirectory:nil file:[[[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject] objectForKey:@"bundleName"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:@"saveBundle"];
}

- (IBAction)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"http://www.sequelpro.com/docs/Bundle_Editor", @"Localized help page for bundle editor - do not localize if no translated webpage is available")]];
}

- (IBAction)reloadBundles:(id)sender
{
	[self showWindow:self];
}

- (IBAction)showWindow:(id)sender
{

	// Suppress parsing if window is already opened
	if(sender != self && [[self window] isVisible]) {
		[super showWindow:sender];
		return;
	}



	// Order out window
	[super showWindow:sender];

	// Re-init commandBundleArray
	[commandBundleArray removeAllObjects];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:0] setObject:[NSMutableArray array] forKey:@"children"];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:1] setObject:[NSMutableArray array] forKey:@"children"];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:2] setObject:[NSMutableArray array] forKey:@"children"];
	[commandsOutlineView reloadData];

	// Load all installed bundle items
	if(bundlePath) {
		NSError *error = nil;
		NSArray *foundBundles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath error:&error];
		if (foundBundles && [foundBundles count]) {
			for(NSString* bundle in foundBundles) {
				if(![[[bundle pathExtension] lowercaseString] isEqualToString:[SPUserBundleFileExtension lowercaseString]]) continue;

				NSError *readError = nil;
				NSString *convError = nil;
				NSPropertyListFormat format;
				NSDictionary *cmdData = nil;
				NSString *infoPath = [NSString stringWithFormat:@"%@/%@/%@", bundlePath, bundle, SPBundleFileName];
				NSData *pData = [NSData dataWithContentsOfFile:infoPath options:NSUncachedRead error:&readError];

				cmdData = [[NSPropertyListSerialization propertyListFromData:pData 
						mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&convError] retain];

				if(!cmdData || readError != nil || [convError length] || !(format == NSPropertyListXMLFormat_v1_0 || format == NSPropertyListBinaryFormat_v1_0)) {
					NSLog(@"“%@/%@” file couldn't be read.", bundle, SPBundleFileName);
					NSBeep();
					if (cmdData) [cmdData release];
				} else {
					if([cmdData objectForKey:SPBundleFileNameKey] && [[cmdData objectForKey:SPBundleFileNameKey] length] && [cmdData objectForKey:SPBundleFileScopeKey])
					{
						NSMutableDictionary *bundleCommand = [NSMutableDictionary dictionary];
						[bundleCommand addEntriesFromDictionary:cmdData];
						[bundleCommand setObject:[bundle stringByDeletingPathExtension] forKey:@"bundleName"];

						[commandBundleArray addObject:bundleCommand];
						if([[cmdData objectForKey:SPBundleFileScopeKey] isEqualToString:SPBundleScopeInputField]) {
							if([cmdData objectForKey:SPBundleFileCategoryKey] && [[cmdData objectForKey:SPBundleFileCategoryKey] length]) {
								BOOL catExists = NO;
								id children = [[[commandBundleTree objectForKey:@"children"] objectAtIndex:0] objectForKey:@"children"];
								for(id child in children) {
									if([child isKindOfClass:[NSDictionary class]] && [child objectForKey:@"children"] && [[child objectForKey:@"bundleName"] isEqualToString:[cmdData objectForKey:SPBundleFileCategoryKey]]) {
										[[child objectForKey:@"children"] addObject:bundleCommand];
										catExists = YES;
										break;
									}
								}
								if(!catExists) {
									NSMutableDictionary *aDict = [NSMutableDictionary dictionary];
									[aDict setObject:[cmdData objectForKey:SPBundleFileCategoryKey] forKey:@"bundleName"];
									[aDict setObject:[NSMutableArray array] forKey:@"children"];
									[[aDict objectForKey:@"children"] addObject:bundleCommand];
									[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:0] objectForKey:@"children"] addObject:aDict];
								}
							} else {
								[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:0] objectForKey:@"children"] addObject:bundleCommand];
							}
						}
						else if([[cmdData objectForKey:SPBundleFileScopeKey] isEqualToString:SPBundleScopeDataTable]) {
							if([cmdData objectForKey:SPBundleFileCategoryKey] && [[cmdData objectForKey:SPBundleFileCategoryKey] length]) {
								BOOL catExists = NO;
								id children = [[[commandBundleTree objectForKey:@"children"] objectAtIndex:1] objectForKey:@"children"];
								for(id child in children) {
									if([child isKindOfClass:[NSDictionary class]] && [child objectForKey:@"children"] && [[child objectForKey:@"bundleName"] isEqualToString:[cmdData objectForKey:SPBundleFileCategoryKey]]) {
										[[child objectForKey:@"children"] addObject:bundleCommand];
										catExists = YES;
										break;
									}
								}
								if(!catExists) {
									NSMutableDictionary *aDict = [NSMutableDictionary dictionary];
									[aDict setObject:[cmdData objectForKey:SPBundleFileCategoryKey] forKey:@"bundleName"];
									[aDict setObject:[NSMutableArray array] forKey:@"children"];
									[[aDict objectForKey:@"children"] addObject:bundleCommand];
									[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:1] objectForKey:@"children"] addObject:aDict];
								}
							} else {
								[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:1] objectForKey:@"children"] addObject:bundleCommand];
							}
						}
						else if([[cmdData objectForKey:SPBundleFileScopeKey] isEqualToString:SPBundleScopeGeneral]) {
							if([cmdData objectForKey:SPBundleFileCategoryKey] && [[cmdData objectForKey:SPBundleFileCategoryKey] length]) {
								BOOL catExists = NO;
								id children = [[[commandBundleTree objectForKey:@"children"] objectAtIndex:2] objectForKey:@"children"];
								for(id child in children) {
									if([child isKindOfClass:[NSDictionary class]] && [child objectForKey:@"children"] && [[child objectForKey:@"bundleName"] isEqualToString:[cmdData objectForKey:SPBundleFileCategoryKey]]) {
										[[child objectForKey:@"children"] addObject:bundleCommand];
										catExists = YES;
										break;
									}
								}
								if(!catExists) {
									NSMutableDictionary *aDict = [NSMutableDictionary dictionary];
									[aDict setObject:[cmdData objectForKey:SPBundleFileCategoryKey] forKey:@"bundleName"];
									[aDict setObject:[NSMutableArray array] forKey:@"children"];
									[[aDict objectForKey:@"children"] addObject:bundleCommand];
									[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:2] objectForKey:@"children"] addObject:aDict];
								}
							} else {
								[[[[commandBundleTree objectForKey:@"children"] objectAtIndex:2] objectForKey:@"children"] addObject:bundleCommand];
							}
						}
					}
					if (cmdData) [cmdData release];
				}
			}
		}
	}

	[removeButton setEnabled:([[commandBundleTreeController selectedObjects] count] > 0)];

	[commandBundleTreeController setContent:commandBundleTree];
	[commandBundleTreeController rearrangeObjects];
	[commandsOutlineView reloadData];
	[commandsOutlineView expandItem:nil expandChildren:YES];

}

- (IBAction)saveAndCloseWindow:(id)sender
{

	// Commit all pending edits
	if([commandBundleTreeController commitEditing]) {

		// Make the bundleNames unique since they represent folder names
		NSMutableDictionary *allNames = [NSMutableDictionary dictionary];
		NSInteger idx = 0;
		for(id item in commandBundleArray) {
			if([allNames objectForKey:[item objectForKey:@"bundleName"]]) {
				NSString *newName = [NSString stringWithFormat:@"%@_%ld", [item objectForKey:@"bundleName"], (NSUInteger)(random() % 35000)];
				[[commandBundleArray objectAtIndex:idx] setObject:newName forKey:@"bundleName"];
			} else {
				[allNames setObject:@"" forKey:[item objectForKey:@"bundleName"]];
			}
			idx++;
		}

		BOOL closeMe = YES;
		for(id item in commandBundleArray) {
			if(![self saveBundle:item atPath:nil]) {
				closeMe = NO;
				NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Error while saving “%@”.", @"error while saving “%@”"), [item objectForKey:@"bundleName"]]
												 defaultButton:NSLocalizedString(@"OK", @"OK button") 
											   alternateButton:nil 
												  otherButton:nil 
									informativeTextWithFormat:@""];
			
				[alert setAlertStyle:NSCriticalAlertStyle];
				[alert runModal];
				break;
			}
		}
		if(closeMe)
			[[self window] performClose:self];
	}

	[[NSApp delegate] reloadBundles:self];

}

- (BOOL)saveBundle:(NSDictionary*)bundle atPath:(NSString*)aPath
{

	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;

	// If passed aPath is nil construct the path from bundle's bundleName.
	// aPath is mainly used for dragging a bundle from table view.
	if(aPath == nil) {
		if(![bundle objectForKey:@"bundleName"] || ![[bundle objectForKey:@"bundleName"] length]) {
			return NO;
		}
		if(!bundlePath)
			bundlePath = [[[NSFileManager defaultManager] applicationSupportDirectoryForSubDirectory:SPBundleSupportFolder createIfNotExists:YES error:nil] retain];
		aPath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, [bundle objectForKey:@"bundleName"], SPUserBundleFileExtension];
	}

	// Create spBundle folder if it doesn't exist
	if(![fm fileExistsAtPath:aPath isDirectory:&isDir]) {
		if(![fm createDirectoryAtPath:aPath withIntermediateDirectories:YES attributes:nil error:nil])
			return NO;
		isDir = YES;
	}
	
	// If aPath exists but it's not a folder bail out
	if(!isDir) return NO;

	// The command.plist file path
	NSString *cmdFilePath = [NSString stringWithFormat:@"%@/%@", aPath, SPBundleFileName];

	NSMutableDictionary *saveDict = [NSMutableDictionary dictionary];
	[saveDict addEntriesFromDictionary:bundle];

	// Remove unnecessary keys
	[saveDict removeObjectsForKeys:[NSArray arrayWithObjects:
		@"bundleName",
		nil]];

	// Remove a given old command.plist file
	[fm removeItemAtPath:cmdFilePath error:nil];
	[saveDict writeToFile:cmdFilePath atomically:YES];

	return YES;

}

/**
 * Sheet did end method
 */
- (void)sheetDidEnd:(id)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)contextInfo
{

	// Order out current sheet to suppress overlapping of sheets
	if ([sheet respondsToSelector:@selector(orderOut:)])
		[sheet orderOut:nil];
	else if ([sheet respondsToSelector:@selector(window)])
		[[sheet window] orderOut:nil];

	if([contextInfo isEqualToString:@"removeSelectedBundles"]) {
		if (returnCode == NSAlertDefaultReturn) {
			
			NSArray *selObjects = [commandBundleTreeController selectedObjects];
			NSArray *selIndexPaths = [commandBundleTreeController selectionIndexPaths];

			for(id obj in selObjects) {

				// Move already installed Bundles to Trash
				NSString *bundleName = [obj objectForKey:@"bundleName"];
				NSString *thePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, bundleName, SPUserBundleFileExtension];
				if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:nil]) {
					NSError *error = nil;
					NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];

					// Use a AppleScript script since NSWorkspace performFileOperation or NSFileManager moveItemAtPath 
					// have problems probably due access rights.
					NSString *moveToTrashCommand = [NSString stringWithFormat:@"osascript -e 'tell application \"Finder\" to move (POSIX file \"%@\") to the trash'", thePath];
					[moveToTrashCommand runBashCommandWithEnvironment:nil atCurrentDirectoryPath:nil error:&error];
					if(error != nil) {
						NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Error while moving “%@” to Trash.", @"error while moving “%@” to trash"), thePath]
														 defaultButton:NSLocalizedString(@"OK", @"OK button") 
													   alternateButton:nil 
														  otherButton:nil 
											informativeTextWithFormat:[error localizedDescription]];
					
						[alert setAlertStyle:NSCriticalAlertStyle];
						[alert runModal];
						break;
					}
				}
			}

			[self reloadBundles:self];

			// Set focus to table view to avoid an unstable state
			[[self window] makeFirstResponder:commandsOutlineView];

			[removeButton setEnabled:([[commandBundleTreeController selectedObjects] count] > 0)];
		}
	} else if([contextInfo isEqualToString:@"saveBundle"]) {
		if (returnCode == NSOKButton) {

			id aBundle = [commandBundleArray objectAtIndex:[commandsOutlineView selectedRow]];

			NSString *bundleFileName = [aBundle objectForKey:@"bundleName"];
			NSString *possibleExisitingBundleFilePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, bundleFileName, SPUserBundleFileExtension];

			NSString *savePath = [sheet filename];

			BOOL isDir;
			BOOL copyingWasSuccessful = YES;
			// Copy possible existing bundle with content
			if([[NSFileManager defaultManager] fileExistsAtPath:possibleExisitingBundleFilePath isDirectory:&isDir] && isDir) {
				if(![[NSFileManager defaultManager] copyItemAtPath:possibleExisitingBundleFilePath toPath:savePath error:nil])
					copyingWasSuccessful = NO;
			}
			if(!copyingWasSuccessful || ![self saveBundle:aBundle atPath:savePath]) {
				NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error while saving the Bundle.", @"error while saving a Bundle")
												 defaultButton:NSLocalizedString(@"OK", @"OK button") 
											   alternateButton:nil 
												  otherButton:nil 
									informativeTextWithFormat:@""];
			
				[alert setAlertStyle:NSCriticalAlertStyle];
				[alert runModal];
			}
		}
	}

}

#pragma mark -
#pragma mark NSWindow delegate

/**
 * Suppress closing of the window if user pressed ESC while inline table cell editing.
 */
- (BOOL)windowShouldClose:(id)sender
{

	if(isTableCellEditing) {
		[commandsOutlineView abortEditing];
		isTableCellEditing = NO;
		[[self window] makeFirstResponder:commandsOutlineView];
		return NO;
	}
	return YES;

}

- (void)windowWillClose:(NSNotification *)notification
{
	// Clear commandBundleArray if window will close to save memory
	[commandBundleArray removeAllObjects];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:0] setObject:[NSMutableArray array] forKey:@"children"];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:1] setObject:[NSMutableArray array] forKey:@"children"];
	[[[commandBundleTree objectForKey:@"children"] objectAtIndex:2] setObject:[NSMutableArray array] forKey:@"children"];
	[commandsOutlineView reloadData];

	// Remove temporary drag file if any
	if(draggedFilePath) {
		[[NSFileManager defaultManager] removeItemAtPath:draggedFilePath error:nil];
		[draggedFilePath release];
		draggedFilePath = nil;
	}
	if(oldBundleName) [oldBundleName release], oldBundleName = nil;

	return YES;
}

#pragma mark -
#pragma mark SRRecorderControl delegate

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{

	if([commandsOutlineView selectedRow] < 0 || [commandsOutlineView selectedRow] > [commandBundleArray count]) return;

	// Transform KeyCombo struct to KeyBinding.dict format for NSMenuItems
	NSMutableString *keyEq = [NSMutableString string];
	NSString *theChar = [[aRecorder keyCharsIgnoringModifiers] lowercaseString];
	[keyEq setString:@""];
	if(newKeyCombo.code > -1) {
		if(newKeyCombo.flags & NSControlKeyMask)
			[keyEq appendString:@"^"];
		if(newKeyCombo.flags & NSAlternateKeyMask)
			[keyEq appendString:@"~"];
		if(newKeyCombo.flags & NSShiftKeyMask) {
			[keyEq appendString:@"$"];
			theChar = [theChar uppercaseString];
		}
		if(newKeyCombo.flags & NSCommandKeyMask)
			[keyEq appendString:@"@"];
		[keyEq appendString:theChar];
	}
	[[[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject] setObject:keyEq forKey:SPBundleFileKeyEquivalentKey];

}

#pragma mark -
#pragma mark outline delegates


- (BOOL)outlineView:(id)outlineView isItemExpandable:(id)item
{
	if([item isKindOfClass:[NSDictionary class]] && [item objectForKey:@"children"])
		return YES;

	return NO;
}

- (NSInteger)outlineView:(id)outlineView numberOfChildrenOfItem:(id)item
{

	if(item == nil)
		item = commandBundleTree;
	
	if([item isKindOfClass:[NSDictionary class]])
		if([item objectForKey:@"children"])
			return [[item objectForKey:@"children"] count];
		else
			return [item count];

	if([item isKindOfClass:[NSArray class]])
		return [item count];
	
	return 0;
}

- (id)outlineView:(id)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{

	if(item && [item respondsToSelector:@selector(objectForKey:)])
		return [item objectForKey:@"bundleName"];
	return @"";

}

- (BOOL)outlineView:outlineView isGroupItem:(id)item
{
	return (![item isLeaf]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	return (![item isLeaf]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return ([item isLeaf]);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] != commandsOutlineView) return;

	[self _updateInputPopupButton];

}

// - (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn
// {
// 	if(outlineView == outlineSchema2) {
// 		[schemaStatusSplitView setPosition:1000 ofDividerAtIndex:0];
// 		[schema12SplitView setPosition:0 ofDividerAtIndex:0];
// 	}
// }
// 
// - (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
// {
// 	// Provide data for our custom type, and simple NSStrings.
// 	[pboard declareTypes:[NSArray arrayWithObjects:DragTableDataFromNavigatorPboardType, DragFromNavigatorPboardType, NSStringPboardType, nil] owner:self];
// 
// 	// Collect the actual schema paths without leading connection ID
// 	NSMutableArray *draggedItems = [NSMutableArray array];
// 	for(id item in items) {
// 		id parentObject = [outlineView parentForItem:item] ? [outlineView parentForItem:item] : schemaData;
// 		if(!parentObject) return NO;
// 		id parentKeys = [parentObject allKeysForObject:item];
// 		if(parentKeys && [parentKeys count] == 1)
// 			[draggedItems addObject:[[[parentKeys objectAtIndex:0] description] stringByReplacingOccurrencesOfRegex:[NSString stringWithFormat:@"^.*?%@", SPUniqueSchemaDelimiter] withString:@""]];
// 	}
// 
// 	// Drag the array with schema paths
// 	NSMutableData *arraydata = [[[NSMutableData alloc] init] autorelease];
// 	NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:arraydata] autorelease];
// 	[archiver encodeObject:draggedItems forKey:@"itemdata"];
// 	[archiver finishEncoding];
// 	[pboard setData:arraydata forType:DragFromNavigatorPboardType];
// 
// 	if([draggedItems count] == 1) {
// 		NSArray *pathComponents = [[draggedItems objectAtIndex:0] componentsSeparatedByString:SPUniqueSchemaDelimiter];
// 		// Is a table?
// 		if([pathComponents count] == 2) {
// 			[pboard setString:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ SELECT * FROM %@", 
// 					[[pathComponents lastObject] backtickQuotedString],
// 					[pathComponents componentsJoinedByPeriodAndBacktickQuoted]
// 				] forType:DragTableDataFromNavigatorPboardType];
// 		}
// 	}
// 	// For external destinations provide a comma separated string
// 	NSMutableString *dragString = [NSMutableString string];
// 	for(id item in draggedItems) {
// 		if([dragString length]) [dragString appendString:@", "];
// 		[dragString appendString:[[item componentsSeparatedByString:SPUniqueSchemaDelimiter] componentsJoinedByPeriodAndBacktickQuotedAndIgnoreFirst]];
// 	}
// 
// 	if(![dragString length]) return NO;
// 
// 	[pboard setString:dragString forType:NSStringPboardType];
// 	return YES;
// }


#pragma mark -
#pragma mark TableView data source and delegate

/**
 * Returns the number of query commandBundleArray.
 */

/*
 * Save spBundle name if inline edited (suppress empty names) and check for renaming and / in the name
 */
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{

	if([aNotification object] != commandsOutlineView) return;

	NSString *newBundleName = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];

	BOOL isValid = YES;

	if(newBundleName && [newBundleName length] && ![newBundleName rangeOfString:@"/"].length) {

		NSString *oldName = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, oldBundleName, SPUserBundleFileExtension];
		NSString *newName = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, newBundleName, SPUserBundleFileExtension];
	
		BOOL isDir;
		NSFileManager *fm = [NSFileManager defaultManager];
		// Check for renaming
		if([fm fileExistsAtPath:oldName isDirectory:&isDir] && isDir) {
			if(![fm moveItemAtPath:oldName toPath:newName error:nil]) {
				isValid = NO;
			}
		}
		// Check if the new name already exists
		else {
			if([fm fileExistsAtPath:newName isDirectory:&isDir] && isDir) {
				isValid = NO;
			}
		}
	} else {
		isValid = NO;
	}

	// If not valid reset name to the old one
	if(!isValid) {
		if(!oldBundleName) oldBundleName = @"New Name";
		[[[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject] setObject:oldBundleName forKey:@"bundleName"];
	}

	[commandsOutlineView reloadData];

	isTableCellEditing = NO;

}

#pragma mark -
#pragma mark Menu validation

/**
 * Menu item validation.
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{

	SEL action = [menuItem action];
	
	if ( (action == @selector(duplicateCommandBundle:)) 
		|| (action == @selector(revealCommandBundleInFinder:))
		|| (action == @selector(saveBundle:))
		) 
	{
		// Allow to record short-cuts used by the Bundle Editor
		if([[NSApp mainWindow] firstResponder] == keyEquivalentField) return NO;
		return ([[commandBundleTreeController selectedObjects] count] == 1);
	}
	else if ( (action == @selector(removeCommandBundle:)) )
	{
		// Allow to record short-cuts used by the Bundle Editor
		if([[NSApp mainWindow] firstResponder] == keyEquivalentField) return NO;
		return ([[commandBundleTreeController selectedObjects] count] > 0);
	}

	return YES;

}

#pragma mark -
#pragma mark TableView drag & drop delegate methods

/**
 * Allow for drag-n-drop out of the application as a copy
 */
- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationMove;
}


/**
 * Drag a table row item as spBundle
 */
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard*)aPboard
{

	if([commandsOutlineView numberOfSelectedRows] != 1 || [rows count] != 1) return NO;

	// Remove old temporary drag file if any
	if(draggedFilePath) {
		[[NSFileManager defaultManager] removeItemAtPath:draggedFilePath error:nil];
		[draggedFilePath release];
		draggedFilePath = nil;
	}

	NSImage *dragImage;
	NSPoint dragPosition;

	NSDictionary *bundleDict = [commandsOutlineView itemAtRow:[rows firstIndex]];
	NSString *bundleFileName = [bundleDict objectForKey:@"bundleName"];
	NSString *possibleExisitingBundleFilePath = [NSString stringWithFormat:@"%@/%@.%@", bundlePath, bundleFileName, SPUserBundleFileExtension];

	draggedFilePath = [[NSString stringWithFormat:@"/tmp/%@.%@", bundleFileName, SPUserBundleFileExtension] retain];


	BOOL isDir;

	// Copy possible existing bundle with content
	if([[NSFileManager defaultManager] fileExistsAtPath:possibleExisitingBundleFilePath isDirectory:&isDir] && isDir) {
		if(![[NSFileManager defaultManager] copyItemAtPath:possibleExisitingBundleFilePath toPath:draggedFilePath error:nil])
			return NO;
	}

	// Write temporary bundle data to disk but do not save the dict to Bundles folder
	if(![self saveBundle:bundleDict atPath:draggedFilePath]) return NO;

	// Write data to the pasteboard
	NSArray *fileList = [NSArray arrayWithObjects:draggedFilePath, nil];
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
	[pboard setPropertyList:fileList forType:NSFilenamesPboardType];

	// Start the drag operation
	dragImage = [[NSWorkspace sharedWorkspace] iconForFile:draggedFilePath];
	dragPosition = [[[self window] contentView] convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
	dragPosition.x -= 32;
	dragPosition.y -= 32;
	[[self window] dragImage:dragImage at:dragPosition offset:NSZeroSize
		event:[NSApp currentEvent] pasteboard:pboard source:[self window] slideBack:YES];

	return YES;

}

#pragma mark -
#pragma mark NSTextView delegates

/**
 * Update command text view for highlighting the current edited line
 */
- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	[commandTextView setNeedsDisplay:YES];
}

/**
 * Traps any editing in editTextView to allow undo grouping only if the text buffer was really changed.
 * Inform the run loop delayed for larger undo groups.
 */
- (void)textDidChange:(NSNotification *)aNotification
{

	if([aNotification object] != commandTextView) return;

	[NSObject cancelPreviousPerformRequestsWithTarget:self
								selector:@selector(setAllowedUndo)
								object:nil];

	// If conditions match create an undo group
	NSInteger cycleCounter;
	if( ( wasCutPaste || allowUndo || doGroupDueToChars ) && ![esUndoManager isUndoing] && ![esUndoManager isRedoing] ) {
		allowUndo = NO;
		wasCutPaste = NO;
		doGroupDueToChars = NO;
		selectionChanged = NO;

		cycleCounter = 0;
		while([esUndoManager groupingLevel] > 0) {
			[esUndoManager endUndoGrouping];
			cycleCounter++;
		}
		while([esUndoManager groupingLevel] < cycleCounter)
			[esUndoManager beginUndoGrouping];

		cycleCounter = 0;
	}

	[self performSelector:@selector(setAllowedUndo) withObject:nil afterDelay:0.09];

}


#pragma mark -
#pragma mark UndoManager methods

/**
 * Establish and return an UndoManager for editTextView
 */
- (NSUndoManager*)undoManagerForTextView:(NSTextView*)aTextView
{
	if (!esUndoManager)
		esUndoManager = [[NSUndoManager alloc] init];

	return esUndoManager;
}

/**
 * Set variable if something in editTextView was cutted or pasted for creating better undo grouping.
 */
- (void)setWasCutPaste
{
	wasCutPaste = YES;
}

/**
 * Will be invoke delayed for creating better undo grouping according to type speed (see [self textDidChange:]).
 */
- (void)setAllowedUndo
{
	allowUndo = YES;
}

/**
 * Will be set if according to characters typed in editTextView for creating better undo grouping.
 */
- (void)setDoGroupDueToChars
{
	doGroupDueToChars = YES;
}

@end

#pragma mark -

@implementation SPBundleEditorController (PrivateAPI)

- (void)_updateInputPopupButton
{

	NSInteger anIndex;

	if([commandsOutlineView selectedRow] < 0 || [commandsOutlineView selectedRow] > [commandBundleArray count]) return;

	NSDictionary *currentDict = [[commandsOutlineView itemAtRow:[commandsOutlineView selectedRow]] representedObject];

	NSString *input = [currentDict objectForKey:SPBundleFileInputSourceKey];
	if(!input || ![input length]) input = SPBundleInputSourceNone;

	NSString *inputfallback = [currentDict objectForKey:SPBundleFileInputSourceFallBackKey];
	if(!inputfallback || ![inputfallback length]) inputfallback = SPBundleInputSourceNone;

	NSString *output = [currentDict objectForKey:SPBundleFileOutputActionKey];
	if(!output || ![output length]) output = SPBundleOutputActionNone;

	NSString *scope = [currentDict objectForKey:SPBundleFileScopeKey];
	if(!scope) scope = SPBundleScopeGeneral;

	if([scope isEqualToString:SPBundleScopeGeneral])
		[scopePopupButton selectItemWithTag:0];
	else if([scope isEqualToString:SPBundleScopeInputField])
		[scopePopupButton selectItemWithTag:1];
	else if([scope isEqualToString:SPBundleScopeDataTable])
		[scopePopupButton selectItemWithTag:2];
	else
		[scopePopupButton selectItemWithTag:10];

	[currentDict setObject:[NSNumber numberWithBool:NO] forKey:SPBundleFileDisabledKey];

	switch([[scopePopupButton selectedItem] tag]) {
		case 0: // General
		[inputPopupButton setMenu:inputNonePopUpMenu];
		[inputPopupButton selectItemAtIndex:0];
		[outputPopupButton setMenu:outputGeneralScopePopUpMenu];
		anIndex = [outputGeneralScopeArray indexOfObject:output];
		if(anIndex == NSNotFound) anIndex = 0;
		[outputPopupButton selectItemAtIndex:anIndex];
		input = SPBundleInputSourceNone;
		[inputFallbackPopupButton setHidden:YES];
		[fallbackLabelField setHidden:YES];
		break;
		case 1: // Input Field
		[inputPopupButton setMenu:inputInputFieldScopePopUpMenu];
		anIndex = [inputInputFieldScopeArray indexOfObject:input];
		if(anIndex == NSNotFound) anIndex = 0;
		[inputPopupButton selectItemAtIndex:anIndex];
		[inputFallbackPopupButton setMenu:inputFallbackInputFieldScopePopUpMenu];
		anIndex = [inputFallbackInputFieldScopeArray indexOfObject:inputfallback];
		if(anIndex == NSNotFound) anIndex = 0;
		[inputFallbackPopupButton selectItemAtIndex:anIndex];
		[outputPopupButton setMenu:outputInputFieldScopePopUpMenu];
		anIndex = [outputInputFieldScopeArray indexOfObject:output];
		if(anIndex == NSNotFound) anIndex = 0;
		[outputPopupButton selectItemAtIndex:anIndex];
		break;
		case 2: // Data Table
		[inputPopupButton setMenu:inputDataTableScopePopUpMenu];
		anIndex = [inputDataTableScopeArray indexOfObject:input];
		if(anIndex == NSNotFound) anIndex = 0;
		[inputPopupButton selectItemAtIndex:anIndex];
		[outputPopupButton setMenu:outputDataTableScopePopUpMenu];
		anIndex = [outputDataTableScopeArray indexOfObject:output];
		if(anIndex == NSNotFound) anIndex = 0;
		[outputPopupButton selectItemAtIndex:anIndex];
		input = SPBundleInputSourceNone;
		[inputFallbackPopupButton setHidden:YES];
		[fallbackLabelField setHidden:YES];
		break;
		case 10: // Disable command
		[currentDict setObject:[NSNumber numberWithBool:YES] forKey:SPBundleFileDisabledKey];
		break;
		default:
		[inputPopupButton setMenu:inputNonePopUpMenu];
		[inputPopupButton selectItemAtIndex:0];
		[outputPopupButton setMenu:outputGeneralScopePopUpMenu];
		anIndex = [outputGeneralScopeArray indexOfObject:output];
		if(anIndex == NSNotFound) anIndex = 0;
		[outputPopupButton selectItemAtIndex:anIndex];
	}

	if([input isEqualToString:SPBundleInputSourceSelectedText]) {
		[inputFallbackPopupButton setHidden:NO];
		[fallbackLabelField setHidden:NO];
	} else {
		[inputFallbackPopupButton setHidden:YES];
		[fallbackLabelField setHidden:YES];
	}

}


@end

