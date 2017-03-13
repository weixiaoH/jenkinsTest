require("UIColor, UIView, UIColor");

defineClass("ViewController", {
    viewDidLoad: function() {
        self.super().viewDidLoad();
        self.view().setBackgroundColor(UIColor.redColor());
        var view = UIView.alloc().initWithFrame({x:20, y:20, width:100, height:100});
        view.setBackgroundColor(UIColor.blueColor());
        self.view().addSubview(view);
    }
}, {});
