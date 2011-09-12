/**
 * KineticJS 2d JavaScript Library v1.0.2
 * http://www.kineticjs.com/
 * Copyright 2011, Eric Rowell
 * Licensed under the MIT or GPL Version 2 licenses.
 * Date: September 2 2011
 *
 * Copyright (C) 2011 by Eric Rowell
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
var Kinetic_2d = function(canvasId){
    this.canvas = document.getElementById(canvasId);
    this.context = this.canvas.getContext("2d");
    this.drawStage = undefined;
    this.listening = false;
    
    // desktop flags
    this.mousePos = null;
    this.mouseDown = false;
    this.mouseUp = false;
    this.mouseOver = false;
    this.mouseMove = false;
    
    // mobile flags
    this.touchPos = null;
    this.touchStart = false;
    this.touchMove = false;
    this.touchEnd = false;
    
    // Region Events
    this.currentRegion = null;
    this.regionIndex = 0;
    this.lastRegionIndex = -1;
    this.mouseOverRegionIndex = -1;
    
    // Animation 
    this.t = 0;
    this.timeInterval = 0;
    this.startTime = 0;
    this.lastTime = 0;
    this.frame = 0;
    this.animating = false;
    
    // provided by Paul Irish
    window.requestAnimFrame = (function(callback){
        return window.requestAnimationFrame ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame ||
        window.oRequestAnimationFrame ||
        window.msRequestAnimationFrame ||
        function(callback){
            window.setTimeout(callback, 1000 / 60);
        };
    })();
};

// ======================================= GENERAL =======================================

Kinetic_2d.prototype.getContext = function(){
    return this.context;
};

Kinetic_2d.prototype.getCanvas = function(){
    return this.canvas;
};

Kinetic_2d.prototype.clear = function(){
    this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
};

Kinetic_2d.prototype.getCanvasPos = function(){
    var obj = this.getCanvas();
    var top = 0;
    var left = 0;
    while (obj.tagName != "BODY") {
        top += obj.offsetTop;
        left += obj.offsetLeft;
        obj = obj.offsetParent;
    }
    return {
        top: top,
        left: left
    };
};

Kinetic_2d.prototype.setDrawStage = function(func){
    this.drawStage = func;
    this.listen();
};

// ======================================= CANVAS EVENTS =======================================

Kinetic_2d.prototype.reset = function(evt){
    if (!evt) {
        evt = window.event;
    }
    
    this.setMousePosition(evt);
    this.setTouchPosition(evt);
    this.regionIndex = 0;
    
    if (!this.animating && this.drawStage !== undefined) {
        this.drawStage();
    }

	// desktop flags
    this.mouseOver = false;
    this.mouseMove = false;
    this.mouseDown = false;
    this.mouseUp = false;
    
	// mobile touch flags
    this.touchStart = false;
    this.touchMove = false;
    this.touchEnd = false;
};

Kinetic_2d.prototype.listen = function(){
    var that = this;
    
    if (this.drawStage !== undefined) {
        this.drawStage();
    }
    
    // desktop events
    this.canvas.addEventListener("mousedown", function(evt){
        that.mouseDown = true;
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("mousemove", function(evt){
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("mouseup", function(evt){
        that.mouseUp = true;
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("mouseover", function(evt){
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("mouseout", function(evt){
        that.mousePos = null;
    }, false);
    
    // mobile events
    this.canvas.addEventListener("touchstart", function(evt){
		evt.preventDefault();
        that.touchStart = true;
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("touchmove", function(evt){
        evt.preventDefault();
        that.reset(evt);
    }, false);
    
    this.canvas.addEventListener("touchend", function(evt){
		evt.preventDefault();
        that.touchEnd = true;
        that.reset(evt);
    }, false);
};

Kinetic_2d.prototype.getMousePos = function(evt){
    return this.mousePos;
};

Kinetic_2d.prototype.getTouchPos = function(evt){
    return this.touchPos;
};

Kinetic_2d.prototype.setMousePosition = function(evt){
    var mouseX = evt.clientX - this.getCanvasPos().left + window.pageXOffset;
    var mouseY = evt.clientY - this.getCanvasPos().top + window.pageYOffset;
    this.mousePos = {
        x: mouseX,
        y: mouseY
    };
};

Kinetic_2d.prototype.setTouchPosition = function(evt){
    if (evt.touches !== undefined && evt.touches.length == 1) { // Only deal with one finger
        var touch = evt.touches[0]; // Get the information for finger #1
        var touchX = touch.pageX - this.getCanvasPos().left + window.pageXOffset;
        var touchY = touch.pageY - this.getCanvasPos().top + window.pageYOffset;
        
        this.touchPos = {
            x: touchX,
            y: touchY
        };
    }
};

// ======================================= REGION EVENTS =======================================

Kinetic_2d.prototype.beginRegion = function(){
    this.currentRegion = {};
    this.regionIndex++;
};

Kinetic_2d.prototype.addRegionEventListener = function(type, func){
    var event = (type.indexOf('touch') == -1) ? 'on' + type : type;
    this.currentRegion[event] = func;
};

Kinetic_2d.prototype.closeRegion = function(){
    var pos = this.touchPos || this.mousePos;
    
    if (pos !== null && this.context.isPointInPath(pos.x, pos.y)) {
        if (this.lastRegionIndex != this.regionIndex) {
            this.lastRegionIndex = this.regionIndex;
        }
        
        // handle onmousedown
        if (this.mouseDown && this.currentRegion.onmousedown !== undefined) {
            this.currentRegion.onmousedown();
            this.mouseDown = false;
        }
        
        // handle onmouseup
        else if (this.mouseUp && this.currentRegion.onmouseup !== undefined) {
            this.currentRegion.onmouseup();
            this.mouseUp = false;
        }
        
        // handle onmouseover
        else if (!this.mouseOver && this.regionIndex != this.mouseOverRegionIndex && this.currentRegion.onmouseover !== undefined) {
            this.currentRegion.onmouseover();
            this.mouseOver = true;
            this.mouseOverRegionIndex = this.regionIndex;
        }
        
        // handle onmousemove
        else if (!this.mouseMove && this.currentRegion.onmousemove !== undefined) {
            this.currentRegion.onmousemove();
            this.mouseMove = true;
        }

        // handle touchstart
        if (this.touchStart && this.currentRegion.touchstart !== undefined) {
            this.currentRegion.touchstart();
            this.touchStart = false;
        }
		        
        // handle touchend
        if (this.touchEnd && this.currentRegion.touchend !== undefined) {
            this.currentRegion.touchend();
            this.touchEnd = false;
        }
		
        // handle touchmove
        if (!this.touchMove && this.currentRegion.touchmove !== undefined) {
            this.currentRegion.touchmove();
            this.touchMove = true;
        }
	
    }
    else if (this.regionIndex == this.lastRegionIndex) {
        this.lastRegionIndex = -1;
        this.mouseOverRegionIndex = -1;
        
        // handle mouseout condition
        if (this.currentRegion.onmouseout !== undefined) {
            this.currentRegion.onmouseout();
        }
    }
};

// ======================================= ANIMATION =======================================

Kinetic_2d.prototype.isAnimating = function(){
    return this.animating;
};

Kinetic_2d.prototype.getFrame = function(){
    return this.frame;
};

Kinetic_2d.prototype.startAnimation = function(){
    this.animating = true;
    var date = new Date();
    this.startTime = date.getTime();
    this.lastTime = this.startTime;
    
    if (this.drawStage !== undefined) {
        this.drawStage();
    }
    
    this.animationLoop();
};

Kinetic_2d.prototype.stopAnimation = function(){
    this.animating = false;
};

Kinetic_2d.prototype.getTimeInterval = function(){
    return this.timeInterval;
};

Kinetic_2d.prototype.getTime = function(){
    return this.t;
};

Kinetic_2d.prototype.getFps = function(){
    return this.timeInterval > 0 ? 1000 / this.timeInterval : 0;
};

Kinetic_2d.prototype.animationLoop = function(){
    var that = this;
    
    this.frame++;
    var date = new Date();
    var thisTime = date.getTime();
    this.timeInterval = thisTime - this.lastTime;
    this.t += this.timeInterval;
    this.lastTime = thisTime;
    
    if (this.drawStage !== undefined) {
        this.drawStage();
    }
    
    if (this.animating) {
        requestAnimFrame(function(){
            that.animationLoop();
        });
    }
};

