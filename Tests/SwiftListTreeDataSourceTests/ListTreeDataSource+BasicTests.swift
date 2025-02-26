import XCTest
import TestsShared
@testable import SwiftListTreeDataSource

class ListTreeDataSourceTests: XCTestCase {
    var data: [OutlineItem] { testDataSet() }
    
    var dataset: [OutlineItem]!
    var sut: ListTreeDataSource<OutlineItem>!
    
    override func setUp() {
        super.setUp()
        dataset = self.data
        setUpSut()
        addItems(dataset, to: sut)
    }
    
    override func tearDown() {
        dataset = nil
        sut = nil
        super.tearDown()
    }

    func setUpSut() {
        sut = ListTreeDataSource<OutlineItem>()
    }
    
    // MARK: - Append/Insert/Delete tests
    
    func test_append_withOneElementToNilParent_shouldAppendAsHead() throws {
        sut = ListTreeDataSource<OutlineItem>() // start from clean state

        let root = OutlineItem(title: "Root")
        sut.append([root], to: nil)
        sut.reload()
        
        XCTAssertEqual((try XCTUnwrap(sut.backingStore.first)).value, root)
    }
    
    func test_append_withOneElementToParent_shouldAppendElementToParent() throws {
        let root = OutlineItem(title: "Root")
        let child = OutlineItem(title: "Child")
        sut.append([root], to: nil)
        sut.append([child], to: root)
        sut.reload()
                
        let rootItem = try XCTUnwrap(sut.backingStore.last)
        XCTAssertEqual(rootItem.value, root)
        XCTAssertEqual( try XCTUnwrap(rootItem.subitems.last).value , child)
    }
    
    func test_append_withRootElementAndChildren_shouldAppendElementsToParents() throws {
        let root1 = OutlineItem(title: "Root1")
        let root1Child1 = OutlineItem(title: "Root1.Child1")
        sut.append([root1], to: nil)
        sut.append([root1Child1], to: root1)

        let root2 = OutlineItem(title: "Root2")
        let root2Child1 = OutlineItem(title: "Root2.Child1")
        let root2Child2 = OutlineItem(title: "Root2.Child2")
        sut.append([root2], to: nil)
        sut.append([root2Child1, root2Child2], to: root2)
        
        sut.reload()
                
        let rootItem1 = try XCTUnwrap(sut.backingStore[safe: sut.backingStore.endIndex-2])
        XCTAssertEqual(rootItem1.value, root1)
        XCTAssertEqual( try XCTUnwrap(rootItem1.subitems.last).value , root1Child1)
        
        let rootItem2 = try XCTUnwrap(sut.backingStore.last)
        XCTAssertEqual(rootItem2.value, root2)
        XCTAssertEqual( try XCTUnwrap(rootItem2.subitems).map(\.value) , [root2Child1, root2Child2])
    }
    
    func test_insertAfterAndBefore_withUITableViewEditingItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "UITableView: Editing")
    }
    
    func test_insertAfterAndBefore_withEditingV1Item_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Editing v1")
    }

    func test_insertAfterAndBefore_withCompositionalItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Compositional")
    }
    
    func test_insertAfterAndBefore_withEditingv2xItem_shouldInsertAtCorrectPosition() throws {
        try verifyInsertionAfterAndBeforeItem(title: "Editing v2.x")
    }

    func test_delete_withFirstItem_shouldRemoveFirstItemAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withLastItem_shouldRemoveFirstItemAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.last )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withLastItemFirstImmediateChild_shouldRemoveLastItemFirstImmediateChildAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.last?.subitems.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    func test_delete_withFirstItemFirstImmediateChild_shouldRemoveFirstItemFirstImmediateChildAndAllChildren() throws {
        let firstItem = try XCTUnwrap( data.first?.subitems.first )
        verifyDeleteItemAndAllChildren(firstItem)
    }
    
    // MARK: - Expand/Collapse tests
    
    func test_expandAll_shouldIncludeAllItems() {
        sut.expandAll()
        
        let flattenedDataSet = depthFirstFlattened(items: dataset)
        let shownItemValues = sut.items.map(\.value)
        XCTAssertEqual(flattenedDataSet, shownItemValues)
    }
    
    func test_collapseAll_withAllExpanded_shouldIncludeOnlyRoots() {
        sut.expandAll()
        sut.reload()

        sut.collapseAll()
        
        let datasetRoots = dataset
        let shownItemValues = sut.items.map(\.value)
        XCTAssertEqual(datasetRoots, shownItemValues)
    }
    
    func test_toggleExpandFirstItem_withAllCollapsed_shouldExpandFirstItemChildren() throws {
        sut.collapseAll()
        
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.toggleExpand(item: firstItem)
        
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItem.subitems {
            XCTAssertTrue( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_expandAllLevelsOfFirstItem_withAllCollapsed_shouldExpandFirstItemAllChildren() throws {
        sut.collapseAll()
     
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.updateAllLevels(of: firstItem, isExpanded: true)
        
        let firstItemWithAllChildren = depthFirstFlattened(items: [firstItem])
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItemWithAllChildren {
            XCTAssertTrue( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_collapseAllLevelsOfFirstItem_withAllExpanded_shouldCollapseFirstItemAllChildren() throws {
        sut.expandAll()
     
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.updateAllLevels(of: firstItem, isExpanded: false)
        
        let firstItemAllChildren = depthFirstFlattened(items: [firstItem]).dropFirst()
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItemAllChildren {
            XCTAssertFalse( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_toggleExpandFirstItem_withAllExpanded_shouldCollapseFirstItemChildren() throws {
        sut.expandAll()
        
        let firstItem = try XCTUnwrap(sut.items.first)
        sut.toggleExpand(item: firstItem)
        
        let shownItemValues = Set( sut.items.map(\.value) )
        for item in firstItem.subitems {
            XCTAssertFalse( shownItemValues.contains(where: { $0 == item.value }) )
        }
    }
    
    func test_expandFirstItem_shouldInsertItemsAfterFirst() throws {
        sut.items.first?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandLastItem_shouldInsertItemsAfterLast() throws {
        sut.items.last?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.append(contentsOf: try XCTUnwrap(expectedData.last?.subitems))
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstItemAndItsFirstImmediateChild_shouldInsertItemsAfterFirstAndItsFirstImmediateChild() throws {
        sut.items.first?.isExpanded = true
        sut.items.first?.subitems.first?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems.first?.subitems), at: 2)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstAndItsSecondImmediateChild_shouldInsertItemsAfterFirstAndItsSecondImmediateChild() throws {
        sut.items.first?.isExpanded = true
        sut.items.first?.subitems[safe: 1]?.isExpanded = true
        sut.reload()
        
        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems), at: 1)
        expectedData.insert(contentsOf: try XCTUnwrap(expectedData.first?.subitems[safe: 1]?.subitems), at: 3)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstItemAllLevels_shouldInsertFirstItemAllChildrenAfterFirst() throws {
        let firstItemFlattened = depthFirstFlattened(items: [try XCTUnwrap(sut.items.first)])
        firstItemFlattened.forEach { $0.isExpanded = true }
        sut.reload()

        let shownItemValues = sut.items.map(\.value)
        
        let firstItemAllChildren = depthFirstFlattened(items: [try XCTUnwrap(dataset.first)]).dropFirst()
        var expectedData = Array(dataset[...])
        expectedData.insert(contentsOf: firstItemAllChildren, at: 1)
        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    func test_expandFirstAndSecondItemsAllLevels_shouldInsertAllChildrenForFirstAndForSecondRespectively() throws {
        let firstTreeItemWithAllChildren = depthFirstFlattened(items: [try XCTUnwrap(sut.items.first)])
        firstTreeItemWithAllChildren.forEach { $0.isExpanded = true }
        let secondTreeItemWithAllChidrenFlattened = depthFirstFlattened(items: [try XCTUnwrap(sut.items[safe: 1])])
        secondTreeItemWithAllChidrenFlattened.forEach { $0.isExpanded = true }
        sut.reload()

        let shownItemValues = sut.items.map(\.value)
        var expectedData = Array(dataset[...])
        
        let firstOutlineItem = dataset.first
        let secondOutlineItem = try XCTUnwrap(dataset[safe: 1])
        
        let theFirstOutlineItemAllChildren = depthFirstFlattened(items: [try XCTUnwrap(firstOutlineItem)]).dropFirst()
        expectedData.insert(contentsOf: theFirstOutlineItemAllChildren, at: 1)
        
        let secondOutlineItemIdx = try XCTUnwrap(expectedData.firstIndex(of: secondOutlineItem))
        let theSecondOutlineItemAllChildren = depthFirstFlattened(items: [secondOutlineItem]).dropFirst()
        expectedData.insert(contentsOf: theSecondOutlineItemAllChildren, at: expectedData.index(after: secondOutlineItemIdx))

        XCTAssertEqual(shownItemValues, expectedData)
    }
    
    // MARK: - Level (Depth) tests
    
    func test_level_withAllExpanded_shouldMatchToCreatedDepthTable() {
        let theDepthLookupTable = depthLookupTable(dataset, itemChildren: { $0.subitems })

        sut.expandAll()
        
        for treeItem in sut.items {
            XCTAssertEqual(treeItem.level, theDepthLookupTable[treeItem.value])
        }
    }
    
    // MARK: - Helpers
    
    func verifyDeleteItemAndAllChildren(_ item: OutlineItem) {
        let firstItemWithAllChildren = depthFirstFlattened(items: [item])
        
        sut.delete([item])
        sut.reload()
        
        let allItemsFlattened = depthFirstFlattened(items: sut.backingStore)
        let allItemSet = Set( allItemsFlattened.map(\.value) )
        for deletedItem in firstItemWithAllChildren {
            XCTAssertFalse( allItemSet.contains(deletedItem) )
        }
    }
    
    func verifyInsertionAfterAndBeforeItem(title: String) throws {
        let existingItem = try XCTUnwrap( depthFirstFlattened(items: self.dataset).first(where: { $0.title.contains(title) }) )
        let existingTreeItem = try XCTUnwrap( sut.lookup(existingItem) )
        
        let insertionAfterItemTitle = "Inserted after \(title)"
        let insertionAfterItem = OutlineItem(title: insertionAfterItemTitle)
        sut.insert([insertionAfterItem], after: existingItem)
        
        let insertionBeforeItemTitle = "Inserted before \(title)"
        let insertionBeforeItem = OutlineItem(title: insertionBeforeItemTitle)
        sut.insert([insertionBeforeItem], before: existingItem)
        sut.reload()
        
        let targerArrayForInsertion = existingTreeItem.parent?.subitems ?? sut.backingStore
        
        let existingItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == existingItem }))
        let insertionAfterItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == insertionAfterItem }))
        let insertionBeforeItemIdx = try XCTUnwrap(targerArrayForInsertion.firstIndex(where: { $0.value == insertionBeforeItem }))
        
        XCTAssertEqual(insertionAfterItemIdx, targerArrayForInsertion.index(after: existingItemIdx))
        XCTAssertEqual(insertionBeforeItemIdx, targerArrayForInsertion.index(before: existingItemIdx))
    }
}


