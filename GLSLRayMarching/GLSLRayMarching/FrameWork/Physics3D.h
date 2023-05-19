//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _Physics3D_h_
#define _Physics3D_h_

#include "Platform.h" 
#include "Component.h"

#include "String.h"

class Physics3D
{
public:
	class BodyComponent : public Component
	{
		friend class Physics3D;
		friend class WorldComponent;

	public:
		BodyComponent(GameObject& gameObject_)
			: Component(gameObject_)
		{
		}

		virtual ~BodyComponent()
		{
		}

	private:
		virtual bool OnInitiate() override
		{
			return true;
		}

		virtual bool OnStart() override
		{
			return true;
		}

		virtual bool OnUpdate() override
		{
			return true;
		}

		virtual bool OnPause() override
		{
			return true;
		}

		virtual void OnResume() override
		{
		}

		virtual void OnStop() override
		{
		}

		virtual void OnTerminate() override
		{
		}
	private:
		virtual void PreSolve(float dt, const Vector3& gravity) = 0;

		virtual void Solve(float dt) = 0;

		virtual void PostSolve(float dt) = 0;
	};

	class TetrahedronMesh
	{
	public:
		std::vector<Vector3> verts;
		std::vector<int> tetIds;
		std::vector<int> edgeIds;
	};

	class SoftBodyProxyComponent : public BodyComponent
	{
		friend class Physics3D;

		int numParticles;
		int numTets;
		int numEdges;
		std::vector<Vector3> pos;
		std::vector<Vector3> prevPos;
		std::vector<Vector3> vel;

		std::vector<int> tetIds;
		std::vector<int> edgeIds;
		std::vector<float> restVol;
		std::vector<float> edgeLengths;
		std::vector<float> invMass;

		float edgeCompliance = edgeCompliance;
		float volCompliance = volCompliance;
	
		std::vector<IVector3> volIdOrder;
	public:
		SoftBodyProxyComponent(GameObject& gameObject_)
			: BodyComponent(gameObject_)
		{
		}

		virtual ~SoftBodyProxyComponent()
		{
		}

		void SetProxyMesh(const TetrahedronMesh& tetMesh, float edgeCompliance = 0.0f, float volCompliance = 0.0f)
		{
			this->numParticles = tetMesh.verts.size();
			this->numTets = tetMesh.tetIds.size() / 4;
			this->numEdges = tetMesh.edgeIds.size() / 2;
			this->pos = tetMesh.verts;
			this->prevPos = tetMesh.verts;
			this->vel = std::vector<Vector3>(this->numParticles);

			this->restVol = std::vector<float>(this->numTets);
			this->edgeLengths = std::vector<float>(this->numEdges);
			this->invMass = std::vector<float>(this->numParticles);

			this->tetIds = tetMesh.tetIds;
			this->edgeIds = tetMesh.edgeIds;

			this->edgeCompliance = edgeCompliance;
			this->volCompliance = volCompliance;

			this->InitPhysics();
			this->ComputeSkinningInfo();

			volIdOrder.resize(4);
			volIdOrder[0] = IVector3(1, 3, 2);
			volIdOrder[1] = IVector3(0, 2, 3);
			volIdOrder[2] = IVector3(0, 3, 1);
			volIdOrder[3] = IVector3(0, 1, 2);
		}
	private:
		virtual bool OnInitiate() override
		{
			return true;
		}

		virtual bool OnStart() override
		{
			return true;
		}

		virtual bool OnUpdate() override
		{
			return true;
		}

		virtual bool OnPause() override
		{
			return true;
		}

		virtual void OnResume() override
		{
		}

		virtual void OnStop() override
		{
		}

		virtual void OnTerminate() override
		{
		}
	private:
		void InitPhysics()
		{
			std::fill(this->invMass.begin(), this->invMass.end(), 0.0f);
			std::fill(this->restVol.begin(), this->restVol.end(), 0.0f);

			for (int i = 0; i < this->numTets; i++)
			{
				float vol = this->GetTetVolume(i);
				this->restVol[i] = vol;

				float pInvMass = vol > 0.0 ? 1.0 / (vol / 4.0) : 0.0;
				this->invMass[this->tetIds[4 * i + 0]] += pInvMass;
				this->invMass[this->tetIds[4 * i + 1]] += pInvMass;
				this->invMass[this->tetIds[4 * i + 2]] += pInvMass;
				this->invMass[this->tetIds[4 * i + 3]] += pInvMass;
			}

			for (int i = 0; i < this->numEdges; i++) {
				int id0 = this->edgeIds[2 * i + 0];
				int id1 = this->edgeIds[2 * i + 1];

				this->edgeLengths[i] = (this->pos[id0] - this->pos[id1]).Length();
			}
		}

		void ComputeSkinningInfo()
		{
		}

		float GetTetVolume(int i)
		{
			int id0 = this->tetIds[4 * i + 0];
			int id1 = this->tetIds[4 * i + 1];
			int id2 = this->tetIds[4 * i + 2];
			int id3 = this->tetIds[4 * i + 3];

			Vector3 edge10 = this->pos[id1] - this->pos[id0];
			Vector3 edge20 = this->pos[id2] - this->pos[id0];
			Vector3 edge30 = this->pos[id3] - this->pos[id0];

			Vector3 normal = edge10.Cross(edge20);
			return normal.Dot(edge30) / 6.0f;
		}

	public:
		virtual void PreSolve(float dt, const Vector3& gravity) override
		{
			for (int i = 0; i < this->numParticles; i++)
			{
				if (this->invMass[i] == 0.0)
					continue;

				this->vel[i] = this->vel[i] + gravity * dt;

				this->prevPos[i] = this->pos[i];

				this->pos[i] = this->pos[i] + this->vel[i] * dt;

				float y = this->pos[i].Y();
				if (y < 0.0)
				{
					this->pos[i] = this->prevPos[i];

					this->pos[i].Y() = 0.0f;
				}
			}
		}

		virtual void Solve(float dt) override
		{
			this->SolveEdges(dt, this->edgeCompliance);
			this->SolveVolumes(dt, this->volCompliance);
		}

		virtual void PostSolve(float dt) override
		{
			for (int i = 0; i < this->numParticles; i++)
			{
				if (this->invMass[i] == 0.0f)
					continue;

				this->vel[i] = (this->pos[i] - this->prevPos[i]) * (1.0 / dt);
			}
		}
	private:
		void SolveEdges(float dt, float compliance)
		{
			float alpha = compliance / Math::Sqr(dt); // XPDB

			for (int i = 0; i < this->edgeLengths.size(); i++)
			{
				int id0 = this->edgeIds[2 * i + 0];
				int id1 = this->edgeIds[2 * i + 1];
				float w0 = this->invMass[id0];
				float w1 = this->invMass[id1];
				float w = w0 + w1;
				if (w == 0.0)
					continue;

				Vector3 gradient;
				gradient = this->pos[id0] - this->pos[id1];
				float len = gradient.Length();
				if (len == 0.0)
					continue;
				gradient *= 1.0 / len;

				float restLen = this->edgeLengths[i];
				float C = len - restLen;
				float s = -C / (w + alpha);

				this->pos[id0] = this->pos[id0] + gradient * (s * w0);
				this->pos[id1] = this->pos[id1] + gradient * (-s * w1);
			}
		}

		void SolveVolumes(float dt, float compliance)
		{
			float alpha = compliance / Math::Sqr(dt); // XPDB

			for (int i = 0; i < this->numTets; i++)  // for each Tet
			{
				float w = 0.0;

				Vector3 gradient[4];
				for (int j = 0; j < 4; j++)          // for each face
				{
					int id0 = this->tetIds[4 * i + this->volIdOrder[j][0]];
					int id1 = this->tetIds[4 * i + this->volIdOrder[j][1]];
					int id2 = this->tetIds[4 * i + this->volIdOrder[j][2]];

					Vector3 edge01 = this->pos[id1] - this->pos[id0];
					Vector3 edge02 = this->pos[id2] - this->pos[id0];

					gradient[j] = edge01.Cross(edge02);
					gradient[j] *= (1.0 / 6.0);

					w += this->invMass[this->tetIds[4 * i + j]] * gradient[j].SquaredLength();
				}
				if (w == 0.0)
					continue;

				float vol = this->GetTetVolume(i);
				float restVol = this->restVol[i];
				float C = vol - restVol;
				float s = -C / (w + alpha);

				for (int j = 0; j < 4; j++) {
					int id = this->tetIds[4 * i + j];
					this->pos[id] = this->pos[id] + gradient[j] * (s * this->invMass[id]);
				}
			}
		}
	};


	class WorldComponent : public Component
	{
		friend class Physics3D;
	public:
		std::list<BodyComponent*> softBodyComponents;


	public:
		WorldComponent(GameObject& gameObject_)
			: Component(gameObject_)
		{
			Physics3D::Manager::GetInstance().Add(this);
		}

		virtual ~WorldComponent()
		{
			Physics3D::Manager::GetInstance().Remove(this);
		}

		void Add(BodyComponent& softBodyComponent)
		{
			softBodyComponents.push_back(&softBodyComponent);
		}

		void Remove(BodyComponent& softBodyComponent)
		{
			auto itr = std::find(softBodyComponents.begin(), softBodyComponents.end(), &softBodyComponent);
			if (itr != softBodyComponents.end())
				softBodyComponents.erase(itr);
		}
	private:
		virtual bool OnInitiate() override
		{
			return true;
		}

		virtual bool OnStart() override
		{
			return true;
		}

		virtual bool OnUpdate() override
		{
			return true;
		}

		virtual bool OnPause() override
		{
			return true;
		}

		virtual void OnResume() override
		{
		}

		virtual void OnStop() override
		{
		}

		virtual void OnTerminate() override
		{
		}

		void FixUpdate(float dt)
		{
			Vector3 gravity = Vector3(0.0f, -9.8f, 0.0f);

			for (auto softBodyComponent : softBodyComponents)
			{
				softBodyComponent->PreSolve(dt, gravity);
				
				softBodyComponent->Solve(dt);

				softBodyComponent->PostSolve(dt);
			}

			OnFixUpdate(dt);
		}


		virtual void OnFixUpdate(float dt)
		{
		}
	};



	class Manager
	{
	private:
		std::vector<WorldComponent*> worldComponents;
	public:
		Manager()
		{
		}

		~Manager()
		{
		}
	public:
		static Physics3D::Manager& GetInstance()
		{
			static Physics3D::Manager instance;

			return instance;
		}

		bool Initialize()
		{
			return true;
		}

		bool Update()
		{
			float dt = Platform::GetDeltaTime();
			for (auto worldComponent : worldComponents)
			{
				worldComponent->FixUpdate(dt);
			}
			return true;
		}

		bool Pause()
		{
			return true;
		}

		void Resume()
		{
		}

		void Terminate()
		{
		}

		void Add(WorldComponent* worldComponent)
		{
			worldComponents.push_back(worldComponent);
		}

		void Remove(WorldComponent* worldComponent)
		{
			auto itr = std::find(worldComponents.begin(), worldComponents.end(), worldComponent);
			if (itr != worldComponents.end())
				worldComponents.erase(itr);
		}
	};

	///////////////////////////////////////////////////////////////////////
public:
	class Service
	{
	public:
		static bool Initialize();
		static bool Update();
		static bool Pause();
		static void Resume();
		static void Terminate();
	};
};

#endif