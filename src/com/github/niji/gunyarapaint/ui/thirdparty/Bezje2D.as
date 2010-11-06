/**
* 2次元ベジェ曲線
* @author nutsu
* @version 0.2
*/

package com.github.niji.gunyarapaint.ui.thirdparty {
	
	import flash.display.Graphics;
	import flash.geom.Point;
	
	public class Bezje2D extends Object{
		
		//始点
		private var _point0:Point;
		//終点
		private var _point1:Point;
		//コントロール点
		private var _control:Point;
		
		//線の長さ
		private var _length:Number;
		
		//積分の定数系
		private var XY:Number;
		private var B:Number;
		private var C:Number;
		private var CS:Number;
		private var CS2:Number;
		private var INTG_0:Number;
		
		
		/**
		* コンストラクタ
		* @param	始点
		* @param	終点
		* @param	コントロール点
		*/
		public function Bezje2D( p0:Point, p1:Point, ctrl:Point ){
			setPoints(p0,p1,ctrl);
		}
		
		
		/**
		* ベジェ関数
		* @param	t( 0～1.0 )
		* @return	座標
		*/
		public function f(t:Number):Point{
			var tp:Number = 1.0 - t;
			return new Point( _point0.x*tp*tp + 2*_control.x*t*tp + _point1.x*t*t,
			                  _point0.y*tp*tp + 2*_control.y*t*tp + _point1.y*t*t );
		}
		
		/**
		* ベジェ関数微分
		* @param	t( 0～1.0 )
		* @return	ベクトル
		*/
		public function diff(t:Number):Point{
			return new Point( 2*( t*( _point0.x + _point1.x - 2*_control.x ) - _point0.x + _control.x ) ,
			                  2*( t*( _point0.y + _point1.y - 2*_control.y ) - _point0.y + _control.y ) );
		}
		
		/**
		* ベジェ関数積分(0からt)
		* @param	t( 0～1.0 )
		* @return	積分値
		*/
		public function integral(t:Number):Number{
			return (integralBezje(t) - INTG_0);
		}
		
		/**
		* 2次元ベジェ曲線の長さ
		* @return	長さ
		*/
		public function get length():Number{
			return _length;
		}
		
		
		//--------------------------------------------------------------------
		
		/**
		* 積分定数初期化
		*/
		private function integralInit():void{
			var kx:Number = _point0.x + _point1.x - 2 * _control.x;
			var ky:Number = _point0.y + _point1.y - 2 * _control.y;
			var ax:Number = - _point0.x + _control.x;
			var ay:Number = - _point0.y + _control.y;
			
			if( kx==0 && ky==0 ){
				XY = 0;
				B  = 0;
				C  = 0;
				CS = CS2 = 1.0;
				_length = 0;
			}else{
				//積分計算の為の定数
				XY = kx*kx + ky*ky;
				B  = ( ax*kx + ay*ky )/XY;
				C  = ( ax*ax + ay*ay )/XY - B*B;
				if( C>1e-10 ){
					CS  = Math.sqrt(C);
					CS2 = 0.0;
				}else{
					C = 0;
					CS = CS2 = 1.0;
				}
				INTG_0  = integralBezje(0.0);
				
				//長さ
				_length = integral(1.0);
			
			}
		}
		
		/**
		* 積分関数
		* @param	t( 0～1.0 )
		* @return	積分結果
		*/
		private function integralBezje( t:Number ):Number{
			var BT:Number  = B+t;
			var BTS:Number = Math.sqrt( BT*BT+C );
			return Math.sqrt(XY) * ( BTS*BT + C * Math.log( (BT + BTS)/CS + CS2 ) );
		}
		
		//--------------------------------------------------------------------
		
		/**
		* 長さからtを得る
		* @param	長さ( 0～length )
		* @param	許容誤差
		* @return t
		*/
		public function length2T( len:Number, d:Number=0.1 ):Number{
			if( len<0 || len>_length ){
				return Number.NaN;
			}else{
				return seekL( len, d );
			}
		}
		
		/**
		* 長さに対するtを得る
		* @param	長さ( 0～length )
		* @param	許容誤差
		* @param	チェックt値
		* @param	次のチェックt値差分
		* @return t
		*/
		private function seekL( len:Number, d:Number=0.1, t0:Number=0.5, td:Number=0.25  ):Number{
			var lent0:Number = integral(t0);
			if( Math.abs( len-lent0 )<d ){
				return t0;
			}else{
				return seekL( len, d, (lent0<len) ? t0+td : t0-td, td/2 );
			}
		}
		
		//--------------------------------------------------------------------
		
		/**
		* 描画
		* @param Graphics
		*/
		public function draw( g:Graphics ):void{
			g.moveTo( _point0.x, _point0.y );
			g.curveTo( _control.x, _control.y, _point1.x, _point1.y );
		}
		
		//--------------------------------------------------------------------
		
		public function get point0():Point{
			return _point0.clone();
		}
		public function get point1():Point{
			return _point1.clone();
		}
		public function get control():Point{
			return _control.clone();
		}
		
		public function set point0(p:Point):void{
			_point0 = p;
			integralInit();
		}
		public function set point1(p:Point):void{
			_point1 = p;
			integralInit();
		}
		public function set control(p:Point):void{
			_control = p;
			integralInit();
		}
		
		public function setPoints( p0:Point, p1:Point, ctrl:Point ):void{
			_point0  = p0;
			_point1  = p1;
			_control = ctrl;
			integralInit();
		}
	}
	
}

