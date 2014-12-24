Cocoa PDF Page Builder
======================

PDFPageBuilder is a Cocoa framework that provides a simple PDF page templating system. A keyed data object is mapped onto a PDF page based on an XML template file.

The included demo app shows how to accurately position text and images on a pre-existing PDF document. It also illustrates how to render multiple objects to a single PDF page and how to generate multiple pages from multiple objects.

![PDFPageBuilder image](./Documents/PageBuilderDemoApp.png?raw=true )

Usage
=====

PDFPageBuilder has no external dependencies so all that is required is to link the framework to your app. Note that the framework installation directory is defined as `@rpath` so the app's Runpath Search Paths build setting will need to be set to `@executable_path/../Frameworks`.

The following method lays out a given object using a url that defines the XML mapping file to a given PDF document page index :

    TSPDFDocument -(void)layoutPageItemsForObject:(id)object withMapURL:(NSURL *)url pageIndex:(NSUInteger)pageIndex

The object must be KVC compliant for the keys defined in the XML mapping file. The mapping file specifies the position and styling to be be applied to the object key values.

PDFPageBuilder has no dependency on PDFView. All rendered objects become part of the PDFDocument and will be saved and printed as such.

Requires 64 bit ARC. 

Box Model
=========

PDFPageBuilder uses a top left based co-ordinate system that corresponds to an NSView flipped context. All dimensions are in mm from the top left hand page corner. A scaling factor can be defined for use in cases where the map file contains dimensions in non mm units.  

XML Map File Format
==========

The map file defines key values which are used to access object properties and provides position and styling information to apply to the property when it is rendered into the PDF page. Both textual and image items can be rendered.

The XML file supports the following elements:

* __Push__ - Push a value onto the named property stack
* __Pop__ - Pop the last value from the named property stack
* __Text__ - Insert a text item based on the value of the element attributes.
* __Run__ - Enables the concatenation of separate elements within a Text element.
* __Image__ - Insert an image item based on the value of the element attributes. 
* __ForEach__ - Iterate over a collection object based on the value of the element attributes.
* __Constant__ - A simple constant value that the client can use to assist with layout.
* __Condition__ - A conditional test that supports boolean AND, OR and ! expressions.
* __True__ - The elements content will be rendered if the enclosing Condition evaluates to true.
* __False__ - The elements content will be rendered if the enclosing Condition evaluates to false.
* __LineBreak__ - Inserts a line break.

Usage of all these elements is illustrated in the [demo map XML file](./PageBuilderDemo/Demo-A4.map.xml).

Credits
=======
PDFPageBuilder is a Cocoa port of a WPF FixedDocument solution design and implemented by Ross Webster. This explains the XAML like nature of the XML mapping file.

Licence
=======

MIT



